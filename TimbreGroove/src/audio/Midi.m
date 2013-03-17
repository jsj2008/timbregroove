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
#import "NoteGenerator.h"
#import "SoundSystem.h"

#import "SoundSystem+Diag.h"

@interface Midi () {
    MidiFreeRange * _freeRange;
    NoteGenerator * _noteGenerator;
}
-(void)attachMidiClientToInstrument:(Instrument *)instrument;

@end


static const char * _getMidiObjectType( MIDIObjectType type, bool *ex )
{
    *ex = false;
    if( type == -1 )
        return "'Other'";
    
    static const char * types[] = {
        "Device", "Entity", "Source", "Destination"
    };
    
    *ex = (type & kMIDIObjectType_ExternalMask) != 0 ;
    type &= ~kMIDIObjectType_ExternalMask;
    return types[type];
}

void MyMIDINotifyProc (const MIDINotification  *message, void *refCon)
{
    static const char * _midiMsgs[8] = {
        "eh, wha?",
        "SetupChanged",
        "ObjectAdded",
        "ObjectRemoved",
        "PropertyChanged",
        "ThruConnectionsChanged",
        "SerialPortOwnerChanged",
        "IOError"
    };
    
    NSMutableString * ms = [NSMutableString stringWithFormat:@"MIDI %p: %s: ", refCon, _midiMsgs[message->messageID]];
    
    if (message->messageID == kMIDIMsgObjectAdded || message->messageID == kMIDIMsgObjectRemoved ) {
        MIDIObjectAddRemoveNotification * arn = (MIDIObjectAddRemoveNotification *)message;
        if( arn->parent )
        {
            bool parentExternal, childExternal;
            const char * parentType = _getMidiObjectType(arn->parentType, &parentExternal);
            const char * childType  = _getMidiObjectType(arn->childType, &childExternal);
            [ms appendFormat:@"Parent: %s%s %p Child: %s%s %p", parentExternal ? "external-" : "", parentType, arn->parent,
              childExternal ? "external-" : "", childType, arn->child];
        }
        else
        {
            bool childExternal;
            const char * childType  = _getMidiObjectType(arn->childType, &childExternal);
            [ms appendFormat:@"%s%s %p", childExternal ? "external-" : "", childType, arn->child];
        }
    }
    else if( message->messageID == kMIDIMsgPropertyChanged )
    {
        MIDIObjectPropertyChangeNotification * pcn = (MIDIObjectPropertyChangeNotification *)message;
        bool isExternal;
        const char * objType = _getMidiObjectType(pcn->objectType, &isExternal);
        char buffer[512];
        CFStringGetCString(pcn->propertyName, buffer, 512, kCFStringEncodingUTF8);
        [ms appendFormat:@"Object: %s%s %p Property: %s", isExternal ? "External-" : "", objType, pcn->object, buffer];
    }
    
    TGLog(LLKindaImportant, @"%@",ms);
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
                TGLog(LLKindaImportant, @"%p %s: %i", (void *)player,_noteNames[noteNumber %12], noteNumber);
            }
#endif
        }
        packet = MIDIPacketNext(packet);
    }
}


@interface MidiFile () {
    NSString *     _midiFileName;
    MusicTimeStamp _playerTrackLength;
    MusicSequence  _currentSequence;
    MusicPlayer    _musicPlayer;
    bool           _midiFilePlaying;
    MusicTimeStamp _midiPauseTime;
    MIDIEndpointRef _myEndPoint;
    
    SoundSystem * _ss;
}
@end

@implementation MidiFile


-(id)initWithMidi:(Midi *)midi
      andFileName:(NSString *)fileName
    andInstrument:(Instrument *)instrument
ss:(SoundSystem *)ss
{
    self = [super init];
    if( self)
    {
        [self setupMidiFile:fileName withInstrument:instrument ss:ss];
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
ss:(SoundSystem *)ss
{
    _ss = ss;
    _myEndPoint = instrument.midiEndPoint;
    _midiFileName = filename;
    
    if( !_musicPlayer )
        CheckError( NewMusicPlayer(&_musicPlayer), "NewMusicPlayer failed" );
    
	NSURL *midiFileURL = [[NSBundle mainBundle] URLForResource:filename
                                                 withExtension: @"mid"];
    
    CheckError( NewMusicSequence(&_currentSequence), "NewMusicSequence failed");
    
    CheckError( MusicSequenceFileLoad(_currentSequence, (__bridge CFURLRef) midiFileURL, 0, 0), "MusicSeqFileLoad failed");
    
//    MusicSequenceSetAUGraph(_currentSequence, ss.processGraph);
    
    CheckError( MusicSequenceSetMIDIEndpoint(_currentSequence, _myEndPoint), "MusicSeqSetEndPoint failed");
    
    TGLog(LLKindaImportant, @"MIDI Sequence targeting endPoint: %p", _myEndPoint);
    

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
        TGLog(LLKindaImportant, @"Pausing Midi at %f",_midiPauseTime);
        CheckError( MusicPlayerStop(_musicPlayer), "MusicPlayerStop failed");
    }
}

-(void)resume
{
    if( _musicPlayer )
    {
        [_ss dumpGraph:_ss.processGraph];
        
        CheckError( MusicPlayerSetTime(_musicPlayer, _midiPauseTime), "MusicPlayerSetTime failed");
        CheckError( MusicPlayerStart(_musicPlayer), "MusicPlayerStart (resume) failed");
        TGLog(LLKindaImportant, @"Resumed Midi at %f",_midiPauseTime);
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

typedef struct _ChannelToEndPoint {
    int             channel;
    MIDIEndpointRef endPoint;
} ChannelToEndPoint;

@interface MidiFreeRange () {
    MIDIPortRef _outPort;
    ChannelToEndPoint _channelMap[16];
}

@end
@implementation MidiFreeRange

-(id)initWithMidi:(Midi *)midi andInstruments:(NSArray *)instruments
{
    self = [super init];
    if( self )
    {
        CheckError (MIDIOutputPortCreate (midi.midiClient,
                                          CFSTR("out port"),
                                          &_outPort
                                          ),
                    " Couldn't create MIDI output port");

        memset(_channelMap, -1, sizeof(_channelMap));
        
        int i = 0;
        [instruments each:^(Instrument * instrument) {
            _channelMap[i].channel = instrument.channel;
            if( !instrument.midiEndPoint )
               [midi attachMidiClientToInstrument:instrument];
            _channelMap[i].endPoint = instrument.midiEndPoint;
        }];
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
    
    MIDIEndpointRef endRef = 0;
    int i;
    for( i = 0; i < (sizeof(_channelMap)/sizeof(_channelMap[0])); i++ )
    {
        if( _channelMap[i].channel == noteMsg->channel )
        {
            endRef = _channelMap[i].endPoint;
            break;
        }
        i++;
    }

    CheckError( MIDISend(_outPort, endRef, &packetList), "Couldn't send note ON");
    
    [NSObject performBlock:[^{
        packetList.packet[ 0]. data[ 0] = 0x80;
        CheckError( MIDISend(_outPort, endRef, &packetList), "Couldn't send note OFF");
    } copy] afterDelay:noteMsg->duration];
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
                                  (__bridge void *)self,
                                  &_midiClient);
        
        CheckError(result,"MIDIClientCreate failed");
        
    }
    return self;
}

-(void)attachMidiClientToInstrument:(Instrument *)instrument
{
    OSStatus result = noErr;
    
    MIDIEndpointRef virtualEndpoint;

    result = MIDIDestinationCreate(_midiClient,
                                   CFSTR("TG Virtual Destination"),
                                   MyMIDIReadProc,
                                   (void *)(instrument.sampler),
                                   &virtualEndpoint);
    
    CheckError(result,"MIDIDestinationCreate failed");

    instrument.midiEndPoint = virtualEndpoint;
}

-(MidiFile *)setupMidiFile:(NSString *)filename withInstrument:(Instrument *)instrument ss:(SoundSystem *)ss
{
    [self attachMidiClientToInstrument:instrument];
    return [[MidiFile alloc] initWithMidi:self andFileName:filename andInstrument:instrument ss:ss];
}

-(MidiFreeRange *)setupMidiFreeRange:(NSArray *)instruments
{
    _freeRange = [[MidiFreeRange alloc] initWithMidi:self andInstruments:instruments];
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
      kParamMIDINote: [Parameter withBlock:[^(MIDINoteMessage *msg) {
        if( _freeRange )
            [_freeRange sendNote:msg];
        } copy]],
      kParamRandomNote: [Parameter withBlock:[^(CGPoint pt) {
        if( _freeRange )
        {
            if( !_noteGenerator )
                _noteGenerator = [[NoteGenerator alloc] initWithScale:kScalePentatonic isRandom:true];
            MIDINoteMessage mnm;
            mnm.note = [_noteGenerator next];
            mnm.duration = 1.1;
            mnm.velocity = 127;
            mnm.channel = 0;
            [_freeRange sendNote:&mnm];
        }
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
