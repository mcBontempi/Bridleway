#import "MapViewController.h"
#import <MapKit/MapKit.h>

@interface MapViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) MKPolylineRenderer *polylineRenderer;
@end

@implementation MapViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self popolateMapWithPolyline];
}

- (void)popolateMapWithPolyline
{
  CLLocationCoordinate2D coordinates[self.pointArray.count];
  
  NSInteger i = 0 ;
  
  for (CLLocation *location in self.pointArray) {
    coordinates[i++] = location.coordinate;
  }
  
  MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coordinates count:self.pointArray.count];
  [self.mapView addOverlay:polyline];
  
  self.polylineRenderer = [[MKPolylineRenderer alloc]initWithPolyline:polyline];
  self.polylineRenderer.strokeColor = [UIColor redColor];
  self.polylineRenderer.lineWidth = 2;
  
}


- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
  return self.polylineRenderer;
 }





- (IBAction)BackPressed:(id)sender {
  
  [self dismissViewControllerAnimated:YES completion:nil];
}


@end
