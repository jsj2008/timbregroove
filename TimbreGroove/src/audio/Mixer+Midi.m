//
//  Mixer+Midi.m
//  TimbreGroove
//
//  Created by victor on 2/10/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Mixer+Midi.h"

void MyMIDINotifyProc (const MIDINotification  *message, void *refCon) {
    printf("MIDI Notify, messageId=%ld,", message->messageID);
}

static char * _noteNames[] = {
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"
};

// Get the MIDI messages as they're sent
static void MyMIDIReadProc(const MIDIPacketList *pktlist,
                           void *refCon,
                           void *connRefCon) {
    
    // Cast our Sampler unit back to an audio unit
    AudioUnit player = (AudioUnit) refCon;

    const MIDITimeStamp kMillion = 1000 * 1000;
    static MIDITimeStamp s_prevTS = 0;
    MIDITimeStamp ts;
    MIDITimeStamp diff;
    
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
    for (int i=0; i < pktlist->numPackets; i++) {
        Byte midiStatus = packet->data[0];
        Byte midiCommand = midiStatus >> 4;
        
        // If the command is note-on
        if (midiCommand == 0x09) {
            Byte note = packet->data[1] & 0x7F;
            Byte velocity = packet->data[2] & 0x7F;

            if( !i )
            {
                ts = packet->timeStamp;
                diff = s_prevTS ? ts - s_prevTS : 0;
                s_prevTS = ts;
            }

            // Log the note letter in a readable format
            int noteNumber = ((int) note) % 12;
            NSLog(@"%s: %i - ts:%lld", _noteNames[noteNumber], noteNumber, diff/kMillion);
            
            // Use MusicDeviceMIDIEvent to send our MIDI message to the sampler to be played
            OSStatus result = MusicDeviceMIDIEvent (player, midiStatus, note, velocity, 0);
            if( result != noErr ) // don't call CheckError unless it really is an error
                CheckError(result, "Error sending note");
            
        }
        packet = MIDIPacketNext(packet);
    }
}

@implementation Mixer (Midi)


-(MIDIEndpointRef)attachMidiClientToSampler:(AudioUnit)sampler
{
    OSStatus result = noErr;
    
    // Create an endpoint
    // In this endpoint we define our client, a name: Virtual Destination
    // a callback function which will receive the MIDI packets: MyMIDIReadProc
    // a reference to the sampler unit for use within our callback
    // a point to our end point: virtualEndpoint
    MIDIEndpointRef virtualEndpoint;
    MIDIReadProc mrp = MyMIDIReadProc;
    result = MIDIDestinationCreate(_midiClient,
                                   CFSTR("TG Virtual Destination"),
                                   mrp,
                                   (void *)sampler,
                                   &virtualEndpoint);
    
    CheckError(result,"MIDIDestinationCreate failed");
    
    return virtualEndpoint;
}

-(void)setupMidi
{
    OSStatus result = noErr;
    
    // Create a client
    // This provides general information about the state of the midi
    // engine to the callback MyMIDINotifyProc

    result = MIDIClientCreate(CFSTR("TG Virtual Client"),
                              MyMIDINotifyProc,
                              NULL,
                              &_midiClient);
    
    CheckError(result,"MIDIClientCreate failed");
    
    CheckError( NewMusicPlayer(&_musicPlayer), "NewMusicPlayer failed" );
}
    
-(void)playMidiFile:(NSString *)filename throughSampler:(AudioUnit)sampler
{    
	NSURL *midiFileURL = [[NSBundle mainBundle] URLForResource:filename
                                                 withExtension: @"mid"];

    CheckError( NewMusicSequence(&_currentSequence), "NewMusicSequence failed");
    
    CheckError( MusicSequenceFileLoad(_currentSequence, (__bridge CFURLRef) midiFileURL, 0, 0), "MusicSeqFileLoad failed");
    
    // MusicSequenceSetAUGraph(s, _processingGraph);
    MIDIEndpointRef endPoint = [self attachMidiClientToSampler:sampler];
    CheckError( MusicSequenceSetMIDIEndpoint(_currentSequence, endPoint), "MusicSeqSetEndPoint failed");

    CheckError( MusicPlayerSetSequence(_musicPlayer, _currentSequence), "MusicPlaySetSeq failed");
    // reduces latency when MusicPlayerStart is called
    CheckError( MusicPlayerPreroll(_musicPlayer), "MusicPlayerPreroll failed" );
    CheckError( MusicPlayerStart(_musicPlayer), "MusicPlayerStart failed" );

    // Get length of track so that we know how long to kill time for
    MusicTrack t;
    UInt32 sz = sizeof(MusicTimeStamp);
    CheckError( MusicSequenceGetIndTrack(_currentSequence, 0, &t), "MusicSeqGetIndTrack failed" );
    CheckError( MusicTrackGetProperty(t, kSequenceTrackProperty_TrackLength, &_playerTrackLength, &sz), "MusicTrackGetProp failed");
}

-(BOOL)isPlayerDone
{
    MusicTimeStamp now = 0;
    MusicPlayerGetTime (_musicPlayer, &now);
    if (now >= _playerTrackLength)
        return NO;

    // Stop the player and dispose of the objects
    MusicPlayerStop(_musicPlayer);
    DisposeMusicSequence(_currentSequence);
    _currentSequence = 0;
    return YES;
}

-(void)midiDealloc
{
    DisposeMusicPlayer(_musicPlayer);
    if( _currentSequence )
        DisposeMusicSequence(_currentSequence);
}
@end
