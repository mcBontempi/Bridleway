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

@interface ViewController () <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
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
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"touttox" ofType:@"gpx"];
    self.root = [GPXParser parseGPXAtPath:path];
    
    [self populateArray];
    
    [self interpolateWith:10];
    
    [self populateMap];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{return;
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

- (void)interpolateWith:(double)metres
{
    __block CLLocation *lastlocation;
    
    __block NSMutableArray * interpolatedArray = [@[] mutableCopy];
    
    [self.mutableArray enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
        
        
        
        
        if (lastlocation) {
            
            double distance = [location distanceFromLocation:lastlocation];
            
            if (distance > metres) {
                
                double bearing = [self bearingToLocation:location fromLocation:lastlocation];
                
                for (int i = 0 ; i < distance / metres ; i++) {
                    
                    CLLocationCoordinate2D cooridinate = [[self class]locationWithBearing:bearing distance:metres*i fromLocation:lastlocation.coordinate];
                    CLLocation *interpolatedLocation = [[CLLocation alloc] initWithLatitude:cooridinate.latitude longitude:cooridinate.longitude];
                    
                    [interpolatedArray addObject:interpolatedLocation];
                    
                }
                
            }
            
        }
        
        lastlocation = location;
        
    }];
    
    [self.mutableArray addObjectsFromArray:interpolatedArray];
}

- (void)populateMap
{
    [self.mutableArray enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        point.coordinate = location.coordinate;
        [self.mapView addAnnotation:point];
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
