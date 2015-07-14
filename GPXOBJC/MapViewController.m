#import "MapViewController.h"
#import <MapKit/MapKit.h>

@interface MapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSMutableArray *polylineArray;
@property (nonatomic, strong) NSMutableArray *rendererArray;
@property (nonatomic, strong) MKTileOverlay *tileOverlay;
@property (nonatomic, assign) MKMapRect boundingRect;
@property (weak, nonatomic) IBOutlet UIButton *zoomButton;
@property (weak, nonatomic) IBOutlet UIButton *zoom2Button;
@end

@implementation MapViewController
- (IBAction)zoomButtonPressed:(id)sender
{
  [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
}
- (IBAction)zoom2ButtonPressed:(id)sender
{
  [self calculateBoundingRect];
    [self.mapView setVisibleMapRect:self.boundingRect animated:YES];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.mapView.delegate = self;
  self.mapView.showsUserLocation = YES;
  self.mapView.mapType = MKMapTypeStandard;
  // [self removeMapTiles];
  [self popolateMapWithPolyline];
  
  [self.mapView setVisibleMapRect:self.boundingRect animated:YES];
    
    self.zoom2Button.selected = YES;
    
}

- (void)removeMapTiles
{
  self.tileOverlay = [[MKTileOverlay alloc] init];
  self.tileOverlay.canReplaceMapContent=NO;
  [self.mapView addOverlay:self.tileOverlay level:MKOverlayLevelAboveLabels];
}

- (void)populateWithPoints
{
  [self.pointArray enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:location.coordinate];
    [self.mapView addAnnotation:annotation];
  }];
}

- (void)calculateBoundingRect
{
  self.boundingRect = MKMapRectNull;
  
  if (self.mapView.userLocation.location) {
    
    MKMapPoint point = MKMapPointForCoordinate(self.mapView.userLocation.location.coordinate);
    self.boundingRect = MKMapRectMake(point.x, point.y,0,0);
  }
  
  [self.polylineArray enumerateObjectsUsingBlock:^(MKPolyline *polyline, NSUInteger idx, BOOL *stop) {
    
    
    if (MKMapRectIsNull(self.boundingRect)) {
      self.boundingRect = [polyline boundingMapRect];
    }
    else {
      self.boundingRect = MKMapRectUnion([polyline boundingMapRect], self.boundingRect);
    }
    
    
  }];
  
  
  self.boundingRect = MKMapRectInset(self.boundingRect, -self.boundingRect.size.width / 2, -self.boundingRect.size.height/2);
  
  
  
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
    renderer.lineWidth = 3;
    
    [self.polylineArray addObject:polyline];
    [self.rendererArray addObject:renderer];
    [self.mapView addOverlay:polyline];
  }];
  
  [self calculateBoundingRect];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
  if([overlay isKindOfClass:[MKTileOverlay class]]) {
    MKTileOverlayRenderer *tileOverlayRenderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:self.tileOverlay];
    return tileOverlayRenderer;
  }
  NSInteger index = [self.polylineArray indexOfObject:overlay];
  return self.rendererArray[index];
}

- (IBAction)BackPressed:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
  if (mode == MKUserTrackingModeNone) {
    
    self.zoomButton.selected = NO;
      self.zoom2Button.selected = YES;
  }
  else if (mode == MKUserTrackingModeFollow) {
    self.zoomButton.selected = NO;
      self.zoom2Button.selected = YES;
  }
  else if (mode == MKUserTrackingModeFollowWithHeading) {
    self.zoomButton.selected = YES;
      self.zoom2Button.selected = NO;
  }
}

@end
