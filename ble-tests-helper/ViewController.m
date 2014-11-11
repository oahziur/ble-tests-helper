//
//  ViewController.m
//  ble-tests-helper
//
//  Created by Rui Zhao on 10/30/14.
//
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController () <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager*      peripheralManager;
@property (strong, nonatomic) NSMutableArray*           adUuids;

// Hear rate service
@property (strong, nonatomic) CBMutableCharacteristic*  heartRateSensorHeartRateCharacteristic;
@property (strong, nonatomic) NSTimer*                  heartRateUpdateTimer;

// Battery service
@property (strong, nonatomic) CBMutableCharacteristic*  batteryLevelCharacteristic;
@property (strong, nonatomic) NSTimer*                  batteryLevelUpdateTimer;

// Chrome API Test service
@property (strong, nonatomic) CBMutableCharacteristic*  testNotifyCharacteristic;
@property (strong, nonatomic) NSTimer*                  testUpdateTimer;

@property (strong, nonatomic) UITextView*               logTextView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    _adUuids = [NSMutableArray array];
    
    // Make app not sleep
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.logTextView = [[UITextView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.logTextView];
    self.logTextView.scrollEnabled = YES;
    self.logTextView.editable = NO;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateHeartRate
{
    if (self.heartRateSensorHeartRateCharacteristic) {
        short heartRate = arc4random() % 20 + 60;
        char heartRateData[2]; heartRateData[0] = 0; heartRateData[1] = heartRate;
        if ([self.peripheralManager updateValue:[NSData dataWithBytes:&heartRateData length:2] forCharacteristic:self.heartRateSensorHeartRateCharacteristic onSubscribedCentrals:nil]) {
            [self logString:@"heart rate characteristic successfully updated"];
        }
    }
}

- (void)addHeartRateService:(CBPeripheralManager*)peripheralManager
{
    CBMutableService* heartRateService = [[CBMutableService alloc]
                                          initWithType:[CBUUID UUIDWithString:@"180D"] primary:YES];
    
    // Define the sensor location characteristic
    char sensorLocation = 5;
    CBMutableCharacteristic* heartRateSensorLocationCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"2A38"] properties:CBCharacteristicPropertyRead value:[NSData dataWithBytes:&sensorLocation length:1] permissions:CBAttributePermissionsReadable];
  
    // Define the heart rate reading characteristic
    self.heartRateSensorHeartRateCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"2A37"] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];

    [self.heartRateUpdateTimer invalidate];
    self.heartRateUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateHeartRate) userInfo:nil repeats:YES];
    
    heartRateService.characteristics = @[heartRateSensorLocationCharacteristic, self.heartRateSensorHeartRateCharacteristic];
    
    [peripheralManager addService:heartRateService];
    
    [self.adUuids addObject:[CBUUID UUIDWithString:@"180D"]];
}

- (void)updateBatteryLevel
{
    if (self.batteryLevelCharacteristic) {
        char batteryLevel = arc4random() % 100;
        if ([self.peripheralManager updateValue:[NSData dataWithBytes:&batteryLevel length:1] forCharacteristic:self.batteryLevelCharacteristic onSubscribedCentrals:nil]) {
            [self logString:@"battery characteristic successfully updated"];
        }
    }
}

- (void)addBatteryService:(CBPeripheralManager*)peripheralManager
{
    CBMutableService* batteryService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"180F"] primary:YES];
    self.batteryLevelCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"2A19"] properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    
    [self.batteryLevelUpdateTimer invalidate];
    self.batteryLevelUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(updateBatteryLevel) userInfo:nil repeats:YES];
    
    batteryService.characteristics = @[self.batteryLevelCharacteristic];
    
    [peripheralManager addService:batteryService];
    
    [self.adUuids addObject:[CBUUID UUIDWithString:@"180F"]];
}

- (void)updateTestCharacteristic
{
    if (self.testNotifyCharacteristic) {
        char val = arc4random();
        if ([self.peripheralManager updateValue:[NSData dataWithBytes:&val length:1] forCharacteristic:self.testNotifyCharacteristic onSubscribedCentrals:nil]) {
            [self logString:@"test characteristic successfully updated"];
        }
    }
}

- (void)addTestService:(CBPeripheralManager*)peripheralManager
{
    
    CBMutableService* includedTestService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"C9D4"] primary:NO];
    [peripheralManager addService:includedTestService];
    
    CBMutableService* testService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:@"C9D3"] primary:YES];
    // included service must be published before referenced service
    testService.includedServices = @[includedTestService];
    
    self.testNotifyCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"C9D5"] properties: CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    [self.testUpdateTimer invalidate];
    self.testUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(updateTestCharacteristic) userInfo:nil repeats:YES];
   
    char testByte = 100;
    
    CBMutableCharacteristic* testReadCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"C9D6"] properties:CBCharacteristicPropertyRead value:[NSData dataWithBytes:&testByte length:1] permissions:CBAttributePermissionsReadable];
    
    CBMutableCharacteristic* testWriteCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"C9D7"] properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
    
    CBMutableCharacteristic* descriptorsCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"C9D8"] properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsWriteable | CBAttributePermissionsReadable];
    
    // Only the Characteristic User Description and Characteristic Presentation Format descriptors are currently supported.
    CBUUID* userDescriptionUuid = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    CBMutableDescriptor* testDescriptor =[[CBMutableDescriptor alloc] initWithType:userDescriptionUuid value:@"user description value"];
    
    // TODO: For some reason: adding service with this descriptor will power off bluetooth on iOS device.
    // CBUUID* presentationFormatUuid = [CBUUID UUIDWithString:CBUUIDCharacteristicFormatString];
    // CBMutableDescriptor* testPresentationDescriptor = [[CBMutableDescriptor alloc] initWithType:presentationFormatUuid value:[NSData dataWithBytes:&testByte length:1]];
    
    descriptorsCharacteristic.descriptors = @[testDescriptor];
    
    testService.characteristics = @[self.testNotifyCharacteristic, testReadCharacteristic, testWriteCharacteristic, descriptorsCharacteristic]; //descriptorsCharacteristic];
    
    [peripheralManager addService:testService];
    [self.adUuids addObject:[CBUUID UUIDWithString:@"C9D3"]];
}

- (void)logString:(NSString*)format, ...
{
    va_list va;
    va_start(va, format);
    self.logTextView.text = [[self.logTextView.text stringByAppendingString:@"\n\n"] stringByAppendingString:[[NSString alloc] initWithFormat:format arguments:va]];
    va_end(va);
}

#pragma mark CBPeripheralManagerDelegate methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    [self logString:@"peripheralManagerDidUpdateState: %@", peripheral];
    
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        [peripheral removeAllServices];
        [peripheral stopAdvertising];
        [self.testUpdateTimer invalidate];
        [self.heartRateUpdateTimer invalidate];
        [self.batteryLevelUpdateTimer invalidate];
        [self.adUuids removeAllObjects];
        return;
    }
    
    [self logString:@"peripheral state is on"];
    
    [self addHeartRateService:peripheral];
    [self addTestService:peripheral];
    [self addBatteryService:peripheral];
    
    NSDictionary *data = @{CBAdvertisementDataLocalNameKey: @"BLE-tests-helper",
                           CBAdvertisementDataServiceUUIDsKey: [self.adUuids copy]};
    [peripheral startAdvertising:data];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict
{
    [self logString:@"peripheralManager:willRestoreState: peripheral:%@ dict: %@", peripheral, dict];
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    [self logString:@"peripheralManagerDidStartAdvertising:error: peripheral:%@ error:%@", peripheral, error];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    [self logString:@"peripheralManager:didAddService:error: peripheral:%@ service:%@ error:%@", peripheral, service, error];
}

#pragma mark - chrome.bluetoothLowEnergy.startCharacteristicNotifications
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    [self logString:@"peripheralManager:central:didSubscribeToCharacteristic: peripheral:%@ central:%@ characteristic:%@", peripheral, central, characteristic];
}

#pragma mark - chrome.bluetoothLowEnergy.stopCharacteristicNotifications
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    [self logString:@"peripheralManager:central:didUnsubscribeFromCharacteristic: peripheral:%@ central:%@ characteristic:%@", peripheral, central, characteristic];
}

/*!
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request for a characteristic with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link must be called.
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    [self logString:@"peripheralManager:didReceiveReadRequest: peripheral:%@ request:%@", peripheral, request];
}

/*!
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request or command for one or more characteristics with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link should be called exactly once. If <i>requests</i> contains
 *                      multiple requests, they must be treated as an atomic unit. If the execution of one of the requests would cause a failure, the request
 *                      and error reason should be provided to <code>respondToRequest:withResult:</code> and none of the requests should be executed.
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    [self logString:@"peripheralManager:didReceiveWriteRequests: peripheral:%@ requests:%@", peripheral, requests];
}


/*!
 *  @method peripheralManagerIsReadyToUpdateSubscribers:
 *
 *  @param peripheral   The peripheral manager providing this update.
 *
 *  @discussion         This method is invoked after a failed call to @link updateValue:forCharacteristic:onSubscribedCentrals: @/link, when <i>peripheral</i> is again
 *                      ready to send characteristic value updates.
 *
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    [self logString:@"peripheralManagerIsReadyToUpdateSubscribers:%@", peripheral];
}

@end
