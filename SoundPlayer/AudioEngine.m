//
//  AudioEngine.m
//  SoundPlayer
//
//  Created by Ziad Hakim on 29.08.17.
//  Copyright © 2017 Ziad Hakim. All rights reserved.
//

#import "AudioEngine.h"

@import AVFoundation;

@interface AudioEngine () {
    AVAudioEngine           *engine;
    AVAudioPlayerNode       *player;
    AVAudioPCMBuffer        *audioBuffer; // audio data buffer for the player
    AVAudioUnitTimePitch    *timePitch;
}

@end

@implementation AudioEngine

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupAudioSession];
        [self setupEngine];
    }
    return self;
}

#pragma mark -
#pragma mark setup audio

- (void)setupAudioSession {
    
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    BOOL success = [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    if (!success) {
        NSLog(@"Error %ld, %@", (long)error.code, error.localizedDescription);
    }
    
    NSTimeInterval bufferDuration =.0058;
    [session setPreferredIOBufferDuration:bufferDuration error:&error];
    if (error) {
        
        NSLog(@"Error %ld, %@", (long)error.code, error.localizedDescription);
    }
    
    double sampleRate = 44100.0;
    [session setPreferredSampleRate:sampleRate error:&error];
    if (error) {
        NSLog(@"Error %ld, %@", (long)error.code, error.localizedDescription);
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:session];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:session];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:session];
    
    
    
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"Error %ld, %@", (long)error.code, error.localizedDescription);
    }
}

- (void)setupEngine {
    
    // 1. create audio buffer
    audioBuffer = [self loadFileIntoBuffer:@"Jiannis-S-Bahn" type:@"m4a"];
    
    // 2. create node
    player = [[AVAudioPlayerNode alloc] init];
    
    timePitch = [[AVAudioUnitTimePitch alloc] init];
    timePitch.pitch = 1.0f;    // Range:     -2400 -> 2400     Default:    1.0
    timePitch.rate = 1.0f;     // Range:     1/32  -> 32.0     Default:    1.0
    
    // 3. create engine
    engine = [[AVAudioEngine alloc] init];
    
    // 4. attach node
    [engine attachNode:player];
    [engine attachNode:timePitch];
    
    // 5. connect nodes
    [engine connect:player to:timePitch format:audioBuffer.format];
    [engine connect:timePitch to:[engine mainMixerNode] format:audioBuffer.format];
    
}

- (void)startEngine {
    
    if (!engine.isRunning) {
        
        NSError *error;
        BOOL success = [engine startAndReturnError:&error];
        NSAssert(success, @"start engine failed, %@", [error localizedDescription]);
        NSLog(@"Audio Engine Started");
    }
}

#pragma mark controll

- (void)updatePitch:(float)pitch {
    timePitch.pitch = pitch;
}

- (void)updateRate:(float)newRate {
    timePitch.rate = newRate;
}

- (void)startPlayer {
    if (!player.isPlaying) {
        [self startEngine];
        [player scheduleBuffer:audioBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
        [player play];
    }
}

- (void)stopPlayer {
    if (player.isPlaying) {
        [player stop];
    }
}

- (BOOL)isPlaying {
    return player.isPlaying;
}

- (AVAudioPCMBuffer *)loadFileIntoBuffer:(NSString *)fileName type:(NSString *)fileType {
    
    BOOL                success = NO;
    NSError             *error = nil;
    AVAudioPCMBuffer    *buffer = nil;
    
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:fileName ofType:fileType]];
    if (url) {
        
        AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:url error:&error];
        buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[audioFile processingFormat] frameCapacity:(AVAudioFrameCount)[audioFile length]];
        success = [audioFile readIntoBuffer:buffer error:&error];
        NSAssert(success, @"couldn't read audioFile into buffer, %@", [error localizedDescription]);
    }
    
    return buffer;
}

#pragma mark -
#pragma mark handle audio interruption notification

- (void)handleInterruption:(NSNotification *)notification {
    
}

- (void)handleRouteChange:(NSNotification *)notification {
    
}

- (void)handleMediaServicesReset:(NSNotification *)notification {
    
}

@end
