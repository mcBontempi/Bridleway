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

#import <MapKit/MapKit.h>

#import <AVFoundation/AVAudioPlayer.h>
#import <AudioToolbox/AudioServices.h>
#import "MapViewController.h"

@interface ViewController () <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) GPXRoot *root;
@property (strong, nonatomic) NSMutableArray *pointArrayArray;
@property (strong, nonatomic) NSMutableArray *interpolatedPointArray;

@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;

@property (nonatomic, assign) NSTimeInterval timeSinceLast;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *sliderLabel;

@property (nonatomic, assign) BOOL found;

@end

@implementation ViewController

- (NSMutableArray *)pointArrayArray
{
  if (!_pointArrayArray) {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ttmp" ofType:@"gpx"];
    self.root = [GPXParser parseGPXAtPath:path];
    
    [self populateArray];
    
  }
  
  return _pointArrayArray;
}

- (IBAction)sliderValueChanged:(id)sender
{
  [self updateSliderLabel];
}

- (void)updateSliderLabel {
  self.sliderLabel.text = [NSString stringWithFormat:@"%.2fm", self.slider.value];
}

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;
  
  self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
  self.locationManager.delegate = self;
  
  [self.locationManager requestWhenInUseAuthorization];
  [self.locationManager startUpdatingLocation];
  
  
  [self interpolateWith:5];
  
  [super viewDidLoad];
  
  self.slider.value = 25;
  
  self.timeSinceLast = [[NSDate date] timeIntervalSince1970];
  
  [self updateSliderLabel];
  
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  MapViewController *vc = segue.destinationViewController;
  
  vc.pointArrayArray = [self.pointArrayArray copy];

 // vc.pointArray = self.interpolatedPointArray;
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
    
    /*
    [self.pointArray enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
      double distance = [location distanceFromLocation:currentLocation];
      minimumDistance = MIN(minimumDistance, distance);
      
      count++;
    }];
    */
    
    [self.interpolatedPointArray enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
      double distance = [location distanceFromLocation:currentLocation];
      minimumDistance = MIN(minimumDistance, distance);
      
      count++;
    }];
    
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
  _pointArrayArray = [@[] mutableCopy];
  [self.root.tracks enumerateObjectsUsingBlock:^(GPXTrack *track, NSUInteger idx, BOOL *stop) {
    
    [track.tracksegments enumerateObjectsUsingBlock:^(GPXTrackSegment *trackSegement, NSUInteger idx, BOOL *stop) {
      __block NSMutableArray *array = [@[] mutableCopy];
      [_pointArrayArray addObject:array];
      [trackSegement.trackpoints  enumerateObjectsUsingBlock:^(GPXTrackPoint *trackPoint, NSUInteger idx, BOOL *stop) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:trackPoint.latitude longitude:trackPoint.longitude];
        [array addObject:location];
      }];
    }];
  }];
  
  [self.root.routes enumerateObjectsUsingBlock:^(GPXRoute *route, NSUInteger idx, BOOL *stop) {
    __block NSMutableArray *array = [@[] mutableCopy];
    [_pointArrayArray addObject:array];
    
    [route.routepoints  enumerateObjectsUsingBlock:^(GPXTrackPoint *trackPoint, NSUInteger idx, BOOL *stop) {
      CLLocation *location = [[CLLocation alloc] initWithLatitude:trackPoint.latitude longitude:trackPoint.longitude];
      [array addObject:location];
    }];
  }];
}

- (void)interpolateWith:(double)metres
{
  self.interpolatedPointArray = [@[] mutableCopy];
  __block CLLocation *lastlocation;
  [self.pointArrayArray enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger idx, BOOL *stop) {
  [array enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
    if (lastlocation) {
      double distance = [location distanceFromLocation:lastlocation];
     // if (distance > metres) {
        double bearing = [self bearingToLocation:location fromLocation:lastlocation];
        for (int i = 0 ; i < distance / metres ; i++) {
          CLLocationCoordinate2D cooridinate = [[self class]locationWithBearing:bearing distance:metres*i fromLocation:lastlocation.coordinate];
          CLLocation *interpolatedLocation = [[CLLocation alloc] initWithLatitude:cooridinate.latitude longitude:cooridinate.longitude];
          [self.interpolatedPointArray addObject:interpolatedLocation];
        }
    //  }
    }
    lastlocation = location;
  }];
  }];
}

+(CLLocationCoordinate2D) locationWithBearing:(float)bearing distance:(float)distanceMeters fromLocation:(CLLocationCoordinate2D)origin {
  CLLocationCoordinate2D target;
  const double distRadians = distanceMeters / (6372797.6); // earth radius in meters
  
  float lat1 = origin.latitude * M_PI / 180;
  float lon1 = origin.longitude * M_PI / 180;
  
  float lat2 = asin( sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing));
  float lon2 = lon1 + atan2( sin(bearing) * sin(distRadians) * cos(lat1),
                            cos(distRadians) - sin(lat1) * sin(lat2) );
  
  target.latitude = lat2 * 180 / M_PI;
  target.longitude = lon2 * 180 / M_PI; // no need to normalize a heading in degrees to be within -179.999999° to 180.00000°
  
  return target;
}

double DegreesToRadians(double degrees) {return degrees * M_PI / 180;};
double RadiansToDegrees(double radians) {return radians * 180/M_PI;};



-(double) bearingToLocation:(CLLocation *)toLocation fromLocation:(CLLocation *)fromLocation {
  
  double lat1 = DegreesToRadians(fromLocation.coordinate.latitude);
  double lon1 = DegreesToRadians(fromLocation.coordinate.longitude);
  
  double lat2 = DegreesToRadians(toLocation.coordinate.latitude);
  double lon2 = DegreesToRadians(toLocation.coordinate.longitude);
  
  double dLon = lon2 - lon1;
  
  double y = sin(dLon) * cos(lat2);
  double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
  double radiansBearing = atan2(y, x);
  
  return radiansBearing;
}


@end
