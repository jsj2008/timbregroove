//
//  Midi.m
//  TimbreGroove
//
//  Created by victor on 2/10/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Midi.h"
#import "Instrument.h"
#import "Names.h"

void MyMIDINotifyProc (const MIDINotification  *message, void *refCon)
{
    NSLog(@"MIDI Notify, messageId=%ld,", message->messageID);
}

//#define SHOW_NOTES

static void MyMIDIReadProc(const MIDIPacketList *pktlist,
                           void *refCon,
                           void *connRefCon) {
    
    // Cast our Sampler unit back to an audio unit
    AudioUnit player = (AudioUnit) refCon;

#ifdef SHOW_NOTES
    static char * _noteNames[] = {
     "C", "C#", "D", "D#", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"
     };
    
    const MIDITimeStamp kMillion = 1000 * 1000;
    static MIDITimeStamp s_prevTS = 0;
    MIDITimeStamp ts;
    MIDITimeStamp diff;
#endif
    
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
    for (int i=0; i < pktlist->numPackets; i++) {
        Byte midiStatus = packet->data[0];
        Byte midiCommand = midiStatus >> 4;
        
        if (midiCommand == 0x09) {
            Byte note = packet->data[1] & 0x7F;
            Byte velocity = packet->data[2] & 0x7F;
#ifdef SHOW_NOTES
            if( !i )
            {
                ts = packet->timeStamp;
                diff = s_prevTS ? ts - s_prevTS : 0;
                s_prevTS = ts;
            }

            int noteNumber = ((int) note) % 12;
            NSLog(@"%s: %i - ts:%lld", _noteNames[noteNumber], noteNumber, diff/kMillion);
#endif
            OSStatus result = MusicDeviceMIDIEvent (player, midiStatus, note, velocity, 0);
            if( result != noErr ) // don't call CheckError unless it really is an error
                CheckError(result, "Error sending note");
            
        }
        packet = MIDIPacketNext(packet);
    }
}

@interface Midi () {
    MIDIClientRef  _midiClient;
    MusicTimeStamp _playerTrackLength;
    MusicSequence  _currentSequence;
    MusicPlayer    _musicPlayer;
    bool           _midiFilePlaying;
    MusicTimeStamp _midiPauseTime;
}
@end

@implementation Midi

-(id)init
{
    self = [super init];
    if( self )
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
        
    }
    return self;
}

-(void)dealloc
{
    DisposeMusicPlayer(_musicPlayer);
    if( _currentSequence )
        DisposeMusicSequence(_currentSequence);    
}

-(MIDIEndpointRef)attachMidiClientToSampler:(AudioUnit)sampler
{
    OSStatus result = noErr;
    
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

-(void)handleParamChange:(NSString const *)paramName value:(NSValue *)value
{
    
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    [putHere addEntriesFromDictionary:
    @{
      kParamTempo: ^(NSValue *v){ [self handleParamChange:kParamTempo value:v]; },
      kParamPitch: ^(NSValue *v){ [self handleParamChange:kParamPitch value:v]; },
      kParamInstrumentP1: ^(NSValue *v){ [self handleParamChange:kParamInstrumentP1 value:v]; },
      kParamInstrumentP2: ^(NSValue *v){ [self handleParamChange:kParamInstrumentP2 value:v]; },
      kParamInstrumentP3: ^(NSValue *v){ [self handleParamChange:kParamInstrumentP3 value:v]; },
      kParamInstrumentP4: ^(NSValue *v){ [self handleParamChange:kParamInstrumentP4 value:v]; },
      kParamInstrumentP5: ^(NSValue *v){ [self handleParamChange:kParamInstrumentP5 value:v]; },
      kParamInstrumentP6: ^(NSValue *v){ [self handleParamChange:kParamInstrumentP6 value:v]; },
      kParamInstrumentP7: ^(NSValue *v){ [self handleParamChange:kParamInstrumentP7 value:v]; },
      kParamInstrumentP8: ^(NSValue *v){ [self handleParamChange:kParamInstrumentP8 value:v]; }
      }];    
}

-(void)playMidiFile:(NSString *)filename withInstrument:(Instrument *)instrument
{

    if( !_musicPlayer )
        CheckError( NewMusicPlayer(&_musicPlayer), "NewMusicPlayer failed" );
    
	NSURL *midiFileURL = [[NSBundle mainBundle] URLForResource:filename
                                                 withExtension: @"mid"];

    CheckError( NewMusicSequence(&_currentSequence), "NewMusicSequence failed");
    
    CheckError( MusicSequenceFileLoad(_currentSequence, (__bridge CFURLRef) midiFileURL, 0, 0), "MusicSeqFileLoad failed");
    
    // MusicSequenceSetAUGraph(s, _processingGraph);
    
    AudioUnit sampler = instrument.sampler;
    
    MIDIEndpointRef endPoint = [self attachMidiClientToSampler:sampler];
    CheckError( MusicSequenceSetMIDIEndpoint(_currentSequence, endPoint), "MusicSeqSetEndPoint failed");

    CheckError( MusicPlayerSetSequence(_musicPlayer, _currentSequence), "MusicPlaySetSeq failed");

    MusicTrack t;
    UInt32 sz = sizeof(MusicTimeStamp);
    CheckError( MusicSequenceGetIndTrack(_currentSequence, 0, &t), "MusicSeqGetIndTrack failed" );
    CheckError( MusicTrackGetProperty(t, kSequenceTrackProperty_TrackLength, &_playerTrackLength, &sz), "MusicTrackGetProp failed");
    MusicTrackLoopInfo loop = { _playerTrackLength, 0 };
    sz = sizeof(loop);
    CheckError( MusicTrackSetProperty(t, kSequenceTrackProperty_LoopInfo, &loop, sz), "MusicTrackGetProp(2) failed");

    // reduces latency when MusicPlayerStart is called
    CheckError( MusicPlayerPreroll(_musicPlayer), "MusicPlayerPreroll failed" );
    
    CheckError( MusicPlayerStart(_musicPlayer), "MusicPlayerStart failed" );
    _midiFilePlaying = true;
    
}

-(void)pause
{
    if( _musicPlayer )
    {
        CheckError( MusicPlayerGetTime(_musicPlayer, &_midiPauseTime), "MusicPlayerGetTime failed");
        NSLog(@"Pausing Midi at %f",_midiPauseTime);
        CheckError( MusicPlayerStop(_musicPlayer), "MusicPlayerStop failed");
    }
}

-(void)resume
{
    if( _musicPlayer )
    {
        CheckError( MusicPlayerSetTime(_musicPlayer, _midiPauseTime), "MusicPlayerSetTime failed");
        CheckError( MusicPlayerStart(_musicPlayer), "MusicPlayerStart (resume) failed");
        NSLog(@"Resumed Midi at %f",_midiPauseTime);
    }
}

-(void)triggersChanged:(Scene *)scene
{
    
}

-(void)update:(NSTimeInterval)dt
{
    
}

-(BOOL)isPlayerDone
{
    /*
    if( !_midiFilePlaying )
        return YES;
    
    MusicTimeStamp now = 0;
    MusicPlayerGetTime (_musicPlayer, &now);
    if (now >= _playerTrackLength)
    {
        // Stop the player and dispose of the objects
        MusicPlayerStop(_musicPlayer);
        DisposeMusicSequence(_currentSequence);
        _currentSequence = 0;
        _midiFilePlaying = false;
        return YES;
    }
     */
    return NO;
}

@end
