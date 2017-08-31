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
    timePitch.pitch = 1.0f;
    timePitch.rate = 1.0f;
    
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
    }
}

#pragma mark -
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
    
    UInt8 type = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    if (type == AVAudioSessionInterruptionTypeBegan) {
        
        [self stopPlayer];
        // tell the delegate to update UI
        if ([self.delegate respondsToSelector:@selector(engineWasInterrupted)]) {
            [self.delegate engineWasInterrupted];
        }
        
    } else if (type == AVAudioSessionInterruptionTypeEnded) {
        
        NSError *error;
        BOOL success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (!success)
        NSLog(@"AVAudioSession set active failed with error: %@", [error localizedDescription]);
    }
}

- (void)handleRouteChange:(NSNotification *)notification {
    
    UInt8 reason = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *previousRoute = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        NSLog(@"NewDeviceAvailable");
        break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        NSLog(@"OldDeviceUnavailable");
        break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
        NSLog(@"CategoryChange");
        NSLog(@"New Category: %@", [[AVAudioSession sharedInstance] category]);
        break;
        case AVAudioSessionRouteChangeReasonOverride:
        NSLog(@"Override");
        break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
        NSLog(@"WakeFromSleep");
        break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
        NSLog(@"NoSuitableRouteForCategory");
        break;
        default:
        NSLog(@"Unknown");
    }
    
    NSLog(@"Previous route: %@", previousRoute);
    

}

- (void)handleMediaServicesReset:(NSNotification *)notification {
    NSLog(@"Media services have been reset! TODO: Re-wiring connections");
    [self setupAudioSession];
    [self setupEngine];
}

@end
