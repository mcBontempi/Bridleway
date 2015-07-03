//
//  ViewController.m
//  GPXOBJC
//
//  Created by Daren David Taylor on 01/07/2015.
//  Copyright (c) 2015 DDT. All rights reserved.
//

#import "ViewController.h"

#import "GPX.h"

#import <CoreLocation/CoreLocation.h>

#import "CLLocation+measuring.h"
#import <MapKit/MapKit.h>

#import <AVFoundation/AVAudioPlayer.h>
#import <AudioToolbox/AudioServices.h>

@interface ViewController () <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) GPXRoot *root;
@property (strong, nonatomic) NSMutableArray *mutableArray;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;
  
  self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
  self.locationManager.headingFilter = 1;
  self.locationManager.delegate = self;
  
  [self.locationManager requestAlwaysAuthorization];
  [self.locationManager startUpdatingLocation];
  
  NSString *path = [[NSBundle mainBundle] pathForResource:@"teanride" ofType:@"gpx"];
  self.root = [GPXParser parseGPXAtPath:path];
  
  [self populateArray];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
  CLLocation *currentLocation = locations.firstObject;
  __block double minimumDistance = MAXFLOAT;
  
  [self.mutableArray enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
    double distance = [location distanceFromLocation:currentLocation];
     minimumDistance = MIN(minimumDistance, distance);
  }];
  NSLog(@"minimum distance%f", minimumDistance);
  
  
  if (minimumDistance > 300) {
    AudioServicesPlaySystemSound (1033);
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
