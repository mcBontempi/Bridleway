//
//  ViewController.m
//  GPXOBJC
//
//  Created by Daren David Taylor on 01/07/2015.
//  Copyright (c) 2015 DDT. All rights reserved.
//

#import "ViewController.h"

#import "GPX.h"

#import "CLLocation+measuring.h"
#import <MapKit/MapKit.h>

#import <AVFoundation/AVAudioPlayer.h>
#import <AudioToolbox/AudioServices.h>

@interface ViewController () <CLLocationManagerDelegate>
@property (strong, nonatomic) GPXRoot *root;
@property (strong, nonatomic) NSMutableArray *mutableArray;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;

@property (nonatomic, assign) NSTimeInterval timeSinceLast;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *sliderLabel;

@property (nonatomic, assign) BOOL found;

@end

@implementation ViewController

- (IBAction)sliderValueChanged:(id)sender
{
  [self updateSliderLabel];
}

- (void)updateSliderLabel {
  self.sliderLabel.text = [NSString stringWithFormat:@"%.2fm", self.slider.value];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.slider.value = 10;
  
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;
  
  self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
 // self.locationManager.distanceFilter = 2;
  
  [self.locationManager requestWhenInUseAuthorization];
  [self.locationManager startUpdatingLocation];
  
  NSString *path = [[NSBundle mainBundle] pathForResource:@"penninewayinterpolated" ofType:@"gpx"];
  self.root = [GPXParser parseGPXAtPath:path];
  
  [self populateArray];
  
  
  self.timeSinceLast = [[NSDate date] timeIntervalSince1970];
  
  
  
  [self updateSliderLabel];
  
  
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
  
  NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
  
  
  if (start - self.timeSinceLast > 5) {
    
    self.timeSinceLast  = start;
  
  CLLocation *currentLocation = locations.firstObject;
  __block double minimumDistance = MAXFLOAT;
  
  __block NSInteger count = 0;
  
  for (int i = 0 ; i < 1 ; i++) {
  
  [self.mutableArray enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
    double distance = [location distanceFromLocation:currentLocation];
     minimumDistance = MIN(minimumDistance, distance);
    
    count++;
  }];
    
  }
  NSLog(@"minimum distance%f", minimumDistance);
  
  NSLog(@"%ld",(long)count);
  
  NSTimeInterval end = [[NSDate date] timeIntervalSince1970];
  
  NSLog(@"%f", end - start );
  
  if (minimumDistance > self.slider.value) {
    AudioServicesPlaySystemSound (1033);
    
    self.found = NO;
  }
  else {
    if (self.found == NO) {
       AudioServicesPlaySystemSound (1028);
    }
    
    self.found = YES;
  }
  
  self.distanceLabel.text = [NSString stringWithFormat:@"%.2fm", minimumDistance];
    
  }
  
}

- (void)populateArray {
  self.mutableArray = [@[] mutableCopy];
  [self.root.tracks enumerateObjectsUsingBlock:^(GPXTrack *track, NSUInteger idx, BOOL *stop) {
    [track.tracksegments enumerateObjectsUsingBlock:^(GPXTrackSegment *trackSegement, NSUInteger idx, BOOL *stop) {
      [trackSegement.trackpoints  enumerateObjectsUsingBlock:^(GPXTrackPoint *trackPoint, NSUInteger idx, BOOL *stop) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:trackPoint.latitude longitude:trackPoint.longitude];
      [self.mutableArray addObject:location];
      }];
    }];
  }];
  
  [self.root.routes enumerateObjectsUsingBlock:^(GPXRoute *route, NSUInteger idx, BOOL *stop) {
      [route.routepoints  enumerateObjectsUsingBlock:^(GPXTrackPoint *trackPoint, NSUInteger idx, BOOL *stop) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:trackPoint.latitude longitude:trackPoint.longitude];
        [self.mutableArray addObject:location];
    }];
  }];
}

@end
