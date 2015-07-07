#import "MapViewController.h"
#import <MapKit/MapKit.h>

@interface MapViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSMutableArray *polylineArray;
@property (nonatomic, strong) NSMutableArray *rendererArray;

@end

@implementation MapViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.mapView.showsUserLocation = YES;
  
  [self popolateMapWithPolyline];
  
  [self populateWithPoints];
}

- (void)populateWithPoints {
  [self.pointArray enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:location.coordinate];
    [self.mapView addAnnotation:annotation];
  }];
  
}

- (void)popolateMapWithPolyline
{
  self.polylineArray = [@[] mutableCopy];
  self.rendererArray = [@[] mutableCopy];
  
  [self.pointArrayArray enumerateObjectsUsingBlock:^(NSArray *pointArray, NSUInteger idx, BOOL *stop) {
    
    CLLocationCoordinate2D coordinates[pointArray.count];
    NSInteger i = 0;
    for (CLLocation *location in pointArray) {
      coordinates[i++] = location.coordinate;
    }
    
    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coordinates count:pointArray.count];
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc]initWithPolyline:polyline];
    renderer.strokeColor = [UIColor redColor];
    renderer.lineWidth = 2;
    
    
    [self.polylineArray addObject:polyline];
    [self.rendererArray addObject:renderer];
    [self.mapView addOverlay:polyline];
    
    
    
    
  }];
  
}


- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
  NSInteger index = [self.polylineArray indexOfObject:overlay];
  
  return self.rendererArray[index];
}



- (IBAction)BackPressed:(id)sender {
  
  [self dismissViewControllerAnimated:YES completion:nil];
}


@end
