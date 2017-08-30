//
//  AudioEngine.h
//  SoundPlayer
//
//  Created by Ziad Hakim on 29.08.17.
//  Copyright © 2017 Ziad Hakim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioEngine : NSObject

@property (nonatomic, assign, readonly) BOOL isPlaying;

- (void)startPlayer;
- (void)stopPlayer;

- (void)updatePitch:(float)pitch;
- (void)updateRate:(float)newRate;

@end
