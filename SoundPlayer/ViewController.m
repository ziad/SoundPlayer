//
//  ViewController.m
//  SoundPlayer
//
//  Created by Ziad Hakim on 29.08.17.
//  Copyright © 2017 Ziad Hakim. All rights reserved.
//

#import "ViewController.h"
#import "AudioEngine.h"

static const NSUInteger     kNumberOfCircles  = 8;
static const CGFloat        kCircleRadius     = 60.0f;

@interface ViewController () <AudioEngineDelegate>

@property (nonatomic, strong) NSArray *circles;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;    // we set min 1 max 10 step 2
@property (weak, nonatomic) IBOutlet UISlider *slider;      // we set min -200 max 200

@property (nonatomic, strong) AudioEngine *audioEngine;
@property (weak, nonatomic) IBOutlet UIView *notenView;

@end

@implementation ViewController

- (IBAction)resetPitch:(id)sender {
    [_stepper setValue:5.0];
    [_slider setValue:0.0];
    [_audioEngine updateRate:1.0];
    [_audioEngine updatePitch:1.0];
    
}

- (IBAction)changeRate:(id)sender {
    
    UIStepper *stepper = (UIStepper *)sender;
    float value = stepper.value/5.0;
    printf("\npitch rate new value: %f",value);
    [_audioEngine updateRate:value];
}

- (IBAction)pitchSlider:(id)sender {
    
    float value = [(UISlider *)sender value];
    [_audioEngine updatePitch:value];
    
}

- (IBAction)togglePlay:(id)sender {
    
    if (_audioEngine.isPlaying) {
        [_audioEngine stopPlayer];
        [_playButton setTitle:@"Play" forState:UIControlStateNormal];
    } else {
        [_audioEngine startPlayer];
        [_playButton setTitle:@"Stop" forState:UIControlStateNormal];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadCircle];
    _audioEngine = [[AudioEngine alloc] init];
    _audioEngine.delegate = self;
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showCircle];
}

- (void)loadCircle {

    NSMutableArray *circles = [NSMutableArray array];
    
    for (int i = 0; i < kNumberOfCircles; i++) {
        UIImageView *note = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Note"]];
        note.alpha = 0;
        note.transform = CGAffineTransformMakeScale(0.5, 0.5);

        [self.notenView addSubview:note];
        [circles addObject:note];
    }
    
    self.circles = [circles copy];
}

- (void)showCircle {
    
    CGFloat angleIncrement = M_PI * 2 / kNumberOfCircles;
    CGPoint center = CGPointMake(CGRectGetWidth(self.notenView.bounds) / 2, CGRectGetHeight(self.notenView.bounds) / 2);
    
    float delay = 0;
    NSUInteger index = 0;
    for (UIView *circle in self.circles) {
        
        [UIView animateWithDuration:0.5 delay:delay options:0 animations:^{
            
            CGPoint position = center;
            position.x += kCircleRadius * sin(angleIncrement * index);
            position.y -= kCircleRadius * cos(angleIncrement * index);
            
            circle.center = position;
            circle.alpha = 1;
            circle.transform = CGAffineTransformIdentity;
            
        }completion:^(BOOL finished){
            
        }];
        
        delay += 0.1;
        index++;
    }
}

- (void)hideCircle {
    
    CGPoint center = CGPointMake(CGRectGetWidth(self.notenView.bounds) / 2, CGRectGetHeight(self.notenView.bounds) / 2);
    float delay = 0;
    
    NSUInteger count = [_circles count];
    do {
        count--;
        UIView *circle = _circles[count];
        
        [UIView animateWithDuration:0.5 delay:delay options:0 animations:^{
            
            circle.center = center;
            circle.alpha = 0;
            circle.transform = CGAffineTransformMakeScale(0.5, 0.5);
            
        } completion:nil];
        delay += 0.1;
        
        
    } while (count > 0);
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self showCircle];
        
    }];
}

#pragma mark <AudioEngineDelegate>

- (void)engineWasInterrupted {
    [_playButton setTitle:@"Play" forState:UIControlStateNormal];
}


@end
