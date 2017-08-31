//
//  AudioEngine.h
//  SoundPlayer
//
//  Created by Ziad Hakim on 29.08.17.
//  Copyright © 2017 Ziad Hakim. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioEngineDelegate <NSObject>

@optional
- (void)engineWasInterrupted;
@end


@interface AudioEngine : NSObject

@property (nonatomic, assign, readonly) BOOL isPlaying;
@property (nonatomic, weak) id<AudioEngineDelegate> delegate;

- (void)startPlayer;
- (void)stopPlayer;

- (void)updatePitch:(float)pitch;   // Range:     -2400 -> 2400     Default:    1.0
- (void)updateRate:(float)newRate;  // Range:     1/32  -> 32.0     Default:    1.0


@end
