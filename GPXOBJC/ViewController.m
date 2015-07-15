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

const double minDistance = 30.0;

@interface ViewController () <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) GPXRoot *root;
@property (strong, nonatomic) NSMutableArray *interpolatedPointArray;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (nonatomic, assign) NSTimeInterval timeSinceLast;
@property (nonatomic, assign) BOOL found;

@property (nonatomic, assign) BOOL prox;
@property (nonatomic, assign) BOOL stat;
@property (weak, nonatomic) IBOutlet UIButton *proxButton;
@property (weak, nonatomic) IBOutlet UIButton *statButton;

@end

@implementation ViewController
- (IBAction)proxPressed:(id)sender {
    
    self.prox = !self.prox;
    
    [self updateProxAndStatButtonsWithStatus];
}
- (IBAction)statPressed:(id)sender {
    
    self.stat = !self.stat;
    
    [self updateProxAndStatButtonsWithStatus];
}

- (NSMutableArray *)pointArrayArray
{
    if (!_pointArrayArray) {
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSString *localPath = [NSString stringWithFormat:@"%@/local.gpx", [url path]];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:localPath];
        if (fileExists) {
            self.root = [GPXParser parseGPXAtPath:localPath];
        } else {
            
            NSString *path = [[NSBundle mainBundle] pathForResource:@"PennineBridelwayDouble" ofType:@"gpx"];
            self.root = [GPXParser parseGPXAtPath:path];
        }
        [self populateArray];
    }
    return _pointArrayArray;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.delegate = self;
    
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
    
    [super viewDidLoad];
    
    [self interpolateWith:5];
    self.timeSinceLast = [[NSDate date] timeIntervalSince1970];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.prox = [defaults boolForKey:@"prox"];
    self.stat = [defaults boolForKey:@"stat"];
    
    
    [self updateProxAndStatButtonsWithStatus];
}

- (void)updateProxAndStatButtonsWithStatus
{
    self.proxButton.selected = self.prox;
    self.statButton.selected = self.stat;
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.prox forKey:@"prox"];
    [defaults setBool:self.stat forKey:@"stat"];
    
    
    [defaults synchronize];
    
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
        
        [self.interpolatedPointArray enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
            double distance = [location distanceFromLocation:currentLocation];
            minimumDistance = MIN(minimumDistance, distance);
        }];
        
        if (minimumDistance > minDistance) {
            if(self.prox) {
                AudioServicesPlaySystemSound (1033);
            }
            self.found = NO;
        }
        else {
            if (self.found == NO) {
                if (self.prox) {
                    AudioServicesPlaySystemSound (1028);
                }
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

- (void)refresh
{
    _pointArrayArray = nil;
    
    [self interpolateWith:5];
    self.timeSinceLast = [[NSDate date] timeIntervalSince1970];
}


@end
