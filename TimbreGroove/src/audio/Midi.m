//
//  Midi.m
//  TimbreGroove
//
//  Created by victor on 2/10/13.
//  Copyright (c) 2013 Ass Over Tea Kettle. All rights reserved.
//

#import "Midi.h"
#import "Sampler.h"
#import "Names.h"
#import "Parameter.h"
#import "NoteGenerator.h"
#import "SoundSystem.h"

#import "SoundSystem+Diag.h"

@interface Midi () {
    NoteGenerator * _noteGenerator;
}
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
    
    NSMutableString * ms = [NSMutableString stringWithFormat:@"MIDI ntfy %p: %s: ", refCon, _midiMsgs[message->messageID]];
    
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
    
    TGLog(LLMidiStuff, @"%@",ms);
}

#define SHOW_NOTES 1

static void MyMIDIReadProc(const MIDIPacketList *pktlist,
                           void *refCon,
                           void *connRefCon)
{
    MIDISendBlock block = (__bridge MIDISendBlock)refCon;
    
#ifdef SHOW_NOTES
    static char * _noteNames[] = {
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"
    };
#endif
    
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
    for (int i=0; i < pktlist->numPackets; i++) {
        
        TGLog(LLMidiStuff, @"MIDI pckt: %d of %d : len:%d ts:%lu", i+1,
              pktlist->numPackets, packet->length, packet->timeStamp);
        
        Byte midiStatus = packet->data[0];
        Byte midiCommand = midiStatus >> 4;
        
        if (midiCommand == 0x09 || midiCommand == 0x08)
        {
            Byte note = packet->data[1] & 0x7F;
            Byte velocity = packet->data[2] & 0x7F;
            
            if(!velocity)
                midiStatus &= ~0x10;
            
            CheckError( block(midiStatus,note,velocity,0), "Error sending note" );
            
#ifdef SHOW_NOTES
            int noteNumber = ((int) note);
            TGLog(LLMidiStuff, @"MIDI nmsg (%p) Status: %04X %s: %i vel:%d", refCon, midiStatus,
                  _noteNames[noteNumber %12], noteNumber, velocity);
#endif
        }
        else
        {
            TGLog(LLMidiStuff, @"MIDI stts %04X",midiStatus);
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
    andInstrument:(id<MidiCapableProtocol>)instrument
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
      withInstrument:(id<MidiCapableProtocol>)instrument
                  ss:(SoundSystem *)ss
{
    _ss = ss;
    _myEndPoint = [instrument endPoint];
    _midiFileName = filename;
    
    if( !_musicPlayer )
        CheckError( NewMusicPlayer(&_musicPlayer), "NewMusicPlayer failed" );
    
	NSURL *midiFileURL = [[NSBundle mainBundle] URLForResource:filename
                                                 withExtension: @"mid"];
    
    CheckError( NewMusicSequence(&_currentSequence), "NewMusicSequence failed");
    CheckError( MusicSequenceFileLoad(_currentSequence, (__bridge CFURLRef) midiFileURL, 0, 0), "MusicSeqFileLoad failed");
    CheckError( MusicSequenceSetMIDIEndpoint(_currentSequence, _myEndPoint), "MusicSeqSetEndPoint failed");
    TGLog(LLMidiStuff, @"Connect MusicSequence %p into endpoint: %p",(void *)_currentSequence,(void *)_myEndPoint);
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
        CheckError( MusicPlayerStop(_musicPlayer), "MusicPlayerStop failed");
        TGLog(LLMidiStuff, @"Pausing Midi at %f",_midiPauseTime);
    }
}

-(void)resume
{
    if( _musicPlayer )
    {
        CheckError( MusicPlayerSetTime(_musicPlayer, _midiPauseTime), "MusicPlayerSetTime failed");
        CheckError( MusicPlayerStart(_musicPlayer), "MusicPlayerStart (resume) failed");
        TGLog(LLMidiStuff, @"Resumed Midi at %f",_midiPauseTime);
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

@interface Midi () {
    MIDIClientRef _midiClient;
}

@end
@implementation Midi

-(id)init
{
    self = [super init];
    if( self )
    {
        OSStatus result = noErr;
        
        result = MIDIClientCreate(CFSTR("TG Virtual Client"),
                                  MyMIDINotifyProc,
                                  (__bridge void *)self,
                                  &_midiClient);
        
        CheckError(result,"MIDIClientCreate failed");
        TGLog(LLMidiStuff, @"Created midi client %d for %@",_midiClient,self);
    }
    return self;
}

-(MidiFile *)setupMidiFile:(NSString *)filename
            withInstrument:(id<MidiCapableProtocol>)instrument
                        ss:(SoundSystem *)ss
{
    return [[MidiFile alloc] initWithMidi:self
                              andFileName:filename
                            andInstrument:instrument
                                       ss:ss];
}


-(void)makeDestination:(id<MidiCapableProtocol>)instrument
{
    MIDIPortRef outPort;
    
    OSStatus result = MIDIOutputPortCreate (_midiClient, CFSTR("out port"), &outPort );
    
    CheckError(result, " Couldn't create MIDI output port");
    
    MIDIEndpointRef virtualEndpoint;
    MIDIReadProc mrp = MyMIDIReadProc;
    id callback = [instrument callback];
    result = MIDIDestinationCreate(_midiClient,
                                   CFSTR("TG Virtual Destination"),
                                   mrp,
                                   (__bridge void *)callback,
                                   &virtualEndpoint);
    
    CheckError(result,"MIDIDestinationCreate failed");
    
    TGLog(LLMidiStuff, @"Created midi endPoint dest. %p (outport %p) for %@",(void *)virtualEndpoint,(void *)outPort,instrument);
    
    [instrument setEndPoint:virtualEndpoint];
    [instrument setOutPort:outPort];
}

-(void)releaseDestination:(id<MidiCapableProtocol>)instrument
{
    CheckError( MIDIEndpointDispose([instrument endPoint]), "Could not dispose endpoint");
    CheckError( MIDIPortDispose([instrument outPort]), "Could not dispose port");
    [instrument setEndPoint:(MIDIEndpointRef)0];
    [instrument setOutPort:(MIDIPortRef)0];
    TGLog(LLMidiStuff, @"Released destination/port for %@",instrument);
}

-(void)sendNote:(MIDINoteMessage *)noteMsg destination:(id<MidiCapableProtocol>)instrument
{
    __block MIDIPacketList packetList;
    packetList.numPackets = 1;
    packetList.packet[ 0]. length = 3;
    packetList.packet[ 0]. data[ 0] = 0x90;
    packetList.packet[ 0]. data[ 1] = noteMsg->note & 0x7F;
    packetList.packet[ 0]. data[ 2] = noteMsg->velocity & 0x7F;
    packetList.packet[ 0]. timeStamp = 0;
    
    MIDIEndpointRef endPoint = [instrument endPoint];
    MIDIPortRef     outPort  = [instrument outPort];
    instrument = nil;
    
    CheckError( MIDISend(outPort, endPoint, &packetList), "Couldn't send note ON");
    
    [NSObject performBlock:[^{
        packetList.packet[ 0]. data[ 0] = 0x80;
        CheckError( MIDISend(outPort, endPoint, &packetList), "Couldn't send note OFF");
    } copy] afterDelay:noteMsg->duration];
}

-(void)setNoteOnOff:(MIDINoteMessage *)noteMsg
        destination:(id<MidiCapableProtocol>)instrument
                 on:(bool)on
{
    __block MIDIPacketList packetList;
    packetList.numPackets = 1;
    packetList.packet[ 0]. length = 3;
    packetList.packet[ 0]. data[ 0] = on ? 0x90 : 0x80;
    packetList.packet[ 0]. data[ 1] = noteMsg->note & 0x7F;
    packetList.packet[ 0]. data[ 2] = noteMsg->velocity & 0x7F;
    packetList.packet[ 0]. timeStamp = 0;
    
    MIDIEndpointRef endPoint = [instrument endPoint];
    MIDIPortRef     outPort  = [instrument outPort];
    instrument = nil;
    
    CheckError( MIDISend(outPort, endPoint, &packetList), on ? "Couldn't send note ON" : "Couldn't send note OFF");
}

-(void)update:(NSTimeInterval)dt
{
    
}


@end
