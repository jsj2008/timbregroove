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
#import "Parameter.h"

void MyMIDINotifyProc (const MIDINotification  *message, void *refCon)
{
    NSLog(@"MIDI Notify, messageId=%ld,", message->messageID);
}

#define SHOW_NOTES 1

static void MyMIDIReadProc(const MIDIPacketList *pktlist,
                           void *refCon,
                           void *connRefCon) {
    
    // Cast our Sampler unit back to an audio unit
    AudioUnit player = (AudioUnit) refCon;
    
#ifdef SHOW_NOTES
    static char * _noteNames[] = {
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"
    };
#endif
    
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
    for (int i=0; i < pktlist->numPackets; i++) {
        Byte midiStatus = packet->data[0];
        Byte midiCommand = midiStatus >> 4;
        
        if (midiCommand == 0x09 || midiCommand == 0x08) {
            Byte note = packet->data[1] & 0x7F;
            Byte velocity = packet->data[2] & 0x7F;
            
            OSStatus result = MusicDeviceMIDIEvent (player, midiStatus, note, velocity, 0);
                CheckError(result, "Error sending note");
            
#ifdef SHOW_NOTES
            if( midiCommand == 0x09 )
            {
                int noteNumber = ((int) note);
                NSLog(@"%s: %i", _noteNames[noteNumber %12], noteNumber);
            }
#endif
        }
        packet = MIDIPacketNext(packet);
    }
}


@interface MidiFile () {
    MusicTimeStamp _playerTrackLength;
    MusicSequence  _currentSequence;
    MusicPlayer    _musicPlayer;
    bool           _midiFilePlaying;
    MusicTimeStamp _midiPauseTime;
}
@end

@implementation MidiFile


-(id)initWithMidi:(Midi *)midi
      andFileName:(NSString *)fileName
    andInstrument:(Instrument *)instrument
{
    self = [super init];
    if( self)
    {
        [self setupMidiFile:fileName withInstrument:instrument];        
    }
    return self;
}

-(void)dealloc
{
    DisposeMusicPlayer(_musicPlayer);
    if( _currentSequence )
        DisposeMusicSequence(_currentSequence);
}

-(void)setupMidiFile:(NSString *)filename
      withInstrument:(Instrument *)instrument
{
    
    if( !_musicPlayer )
        CheckError( NewMusicPlayer(&_musicPlayer), "NewMusicPlayer failed" );
    
	NSURL *midiFileURL = [[NSBundle mainBundle] URLForResource:filename
                                                 withExtension: @"mid"];
    
    CheckError( NewMusicSequence(&_currentSequence), "NewMusicSequence failed");
    
    CheckError( MusicSequenceFileLoad(_currentSequence, (__bridge CFURLRef) midiFileURL, 0, 0), "MusicSeqFileLoad failed");
    
    // MusicSequenceSetAUGraph(s, _processingGraph);
    
    CheckError( MusicSequenceSetMIDIEndpoint(_currentSequence, instrument.midiEndPoint), "MusicSeqSetEndPoint failed");
    
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
}

-(void) start
{
    if( _musicPlayer )
    {
        CheckError( MusicPlayerStart(_musicPlayer), "MusicPlayerStart failed" );
        _midiFilePlaying = true;
    }
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

/*
-(BOOL)isPlayerDone
{
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
    return NO;
}
*/

@end

@interface MidiFreeRange () {
    MIDIPortRef _outPort;
    NSArray * _midiRefs;
}

@end
@implementation MidiFreeRange

-(id)initWithMidi:(Midi *)midi andMidiRefs:(NSArray *)midiRefs
{
    self = [super init];
    if( self )
    {
        CheckError (MIDIOutputPortCreate (midi.midiClient,
                                          CFSTR("out port"),
                                          &_outPort
                                          ),
                    " Couldn't create MIDI output port");

        _midiRefs = midiRefs;
    }
    return self;
}

-(void)sendNote:(MIDINoteMessage *)noteMsg
{
    __block MIDIPacketList packetList;
    packetList.numPackets = 1;
    packetList.packet[ 0]. length = 3;
    packetList.packet[ 0]. data[ 0] = 0x90;
    packetList.packet[ 0]. data[ 1] = noteMsg->note & 0x7F;
    packetList.packet[ 0]. data[ 2] = noteMsg->velocity & 0x7F;
    packetList.packet[ 0]. timeStamp = 0;
    
    MIDIEndpointRef endRef = [_midiRefs[noteMsg->channel] pointerValue];
    CheckError( MIDISend(_outPort, endRef, &packetList), "Couldn't send note ON");
    
    [NSObject performBlock:[^{
        packetList.packet[ 0]. data[ 0] = 0x80;
        CheckError( MIDISend(_outPort, endRef, &packetList), "Couldn't send note OFF");
    } copy] afterDelay:noteMsg->duration];
}
@end

@interface Midi () {
    MidiFreeRange * _freeRange;
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

-(void)attachMidiClientToInstrument:(Instrument *)instrument
{
    OSStatus result = noErr;
    
    MIDIEndpointRef virtualEndpoint;
    MIDIReadProc mrp = MyMIDIReadProc;

    result = MIDIDestinationCreate(_midiClient,
                                   CFSTR("TG Virtual Destination"),
                                   mrp,
                                   (void *)(instrument.sampler),
                                   &virtualEndpoint);
    
    CheckError(result,"MIDIDestinationCreate failed");

    instrument.midiEndPoint = virtualEndpoint;
}

-(MidiFile *)setupMidiFile:(NSString *)filename withInstrument:(Instrument *)instrument
{
    [self attachMidiClientToInstrument:instrument];
    return [[MidiFile alloc] initWithMidi:self andFileName:filename andInstrument:instrument];
}

-(MidiFreeRange *)setupMidiFreeRange:(NSArray *)instruments
{
    NSArray * midiRefs = [instruments map:^id(Instrument * instrument) {
        [self attachMidiClientToInstrument:instrument];
        return [NSValue valueWithPointer:(const void *)instrument.midiEndPoint];
    }];

    _freeRange = [[MidiFreeRange alloc] initWithMidi:self andMidiRefs:midiRefs];
    return _freeRange;
}

-(void)handleParamChange:(NSString const *)paramName value:(float)value
{
    
}

-(void)getParameters:(NSMutableDictionary *)putHere
{
    FloatParamBlock(^closure)(NSString const * name) =
        ^FloatParamBlock(NSString const * name){
        return ^(float f) {
            [self handleParamChange:name value:f ];
        };
    };
    
    [putHere addEntriesFromDictionary:
    @{
      kParamTempo: [Parameter withBlock:[closure(kParamTempo) copy]],
      kParamPitch: [Parameter withBlock:[closure(kParamPitch) copy]],
      kParamInstrumentP1: [Parameter withBlock:[closure(kParamInstrumentP1) copy]],
      kParamInstrumentP2: [Parameter withBlock:[closure(kParamInstrumentP2) copy]],
      kParamInstrumentP3: [Parameter withBlock:[closure(kParamInstrumentP3) copy]],
      kParamInstrumentP4: [Parameter withBlock:[closure(kParamInstrumentP4) copy]],
      kParamInstrumentP5: [Parameter withBlock:[closure(kParamInstrumentP5) copy]],
      kParamInstrumentP6: [Parameter withBlock:[closure(kParamInstrumentP6) copy]],
      kParamInstrumentP7: [Parameter withBlock:[closure(kParamInstrumentP7) copy]],
      kParamInstrumentP8: [Parameter withBlock:[closure(kParamInstrumentP8) copy]],
      kParamMIDINote: [Parameter withBlock:[^(MIDINoteMessage *msg){
            if( _freeRange )
               [_freeRange sendNote:msg];
        } copy]]
      }];
}


-(void)triggersChanged:(Scene *)scene
{
    
}

-(void)update:(NSTimeInterval)dt
{
    
}


@end
