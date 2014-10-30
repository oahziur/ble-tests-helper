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

@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) NSMutableArray            *adUuids;

// Hear rate service
@property (strong, nonatomic) CBMutableCharacteristic   *heartRateSensorHeartRateCharacteristic;
@property (strong, nonatomic) CBMutableCharacteristic   *heartRateSensorLocationCharacteristic;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    _adUuids = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addHeartRateService:(CBPeripheralManager*)peripheralManager
{
    // Define the heart rate service
    CBMutableService *heartRateService = [[CBMutableService alloc]
                                          initWithType:[CBUUID UUIDWithString:@"180D"] primary:true];
    
    // Define the sensor location characteristic
    char sensorLocation = 5;
    self.heartRateSensorLocationCharacteristic = [[CBMutableCharacteristic alloc]
                                                                      initWithType:[CBUUID UUIDWithString:@"0x2A38"]
                                                                      properties:CBCharacteristicPropertyRead
                                                                      value:[NSData dataWithBytes:&sensorLocation length:1]
                                                                      permissions:CBAttributePermissionsReadable];
    
  
    // Define the heart rate reading characteristic
    self.heartRateSensorHeartRateCharacteristic = [[CBMutableCharacteristic alloc]
                                                   initWithType:[CBUUID UUIDWithString:@"2A37"]
                                                   properties: CBCharacteristicPropertyNotify
                                                   value:nil
                                                   permissions:CBAttributePermissionsReadable];
    
    // Add the characteristics to the service
    heartRateService.characteristics = 
    @[self.heartRateSensorLocationCharacteristic, self.heartRateSensorHeartRateCharacteristic];
    
    // Add the service to the peripheral manager    
    [peripheralManager addService:heartRateService];
    
    [self.adUuids addObject:[CBUUID UUIDWithString:@"180D"]];
}


#pragma mark CBPeripheralManagerDelegate methods


/*!
 *  @method peripheralManagerDidUpdateState:
 *
 *  @param peripheral   The peripheral manager whose state has changed.
 *
 *  @discussion         Invoked whenever the peripheral manager's state has been updated. Commands should only be issued when the state is
 *                      <code>CBPeripheralManagerStatePoweredOn</code>. A state below <code>CBPeripheralManagerStatePoweredOn</code>
 *                      implies that advertisement has paused and any connected centrals have been disconnected. If the state moves below
 *                      <code>CBPeripheralManagerStatePoweredOff</code>, advertisement is stopped and must be explicitly restarted, and the
 *                      local database is cleared and all services must be re-added.
 *
 *  @see                state
 *
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState: %@", peripheral);
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    [self  addHeartRateService:peripheral];
    NSDictionary *data = @{CBAdvertisementDataLocalNameKey: @"BLE-tests-helper",
                           CBAdvertisementDataServiceUUIDsKey: [self.adUuids copy]};
    [peripheral startAdvertising:data];
}


/*!
 *  @method peripheralManager:willRestoreState:
 *
 *  @param peripheral	The peripheral manager providing this information.
 *  @param dict			A dictionary containing information about <i>peripheral</i> that was preserved by the system at the time the app was terminated.
 *
 *  @discussion			For apps that opt-in to state preservation and restoration, this is the first method invoked when your app is relaunched into
 *						the background to complete some Bluetooth-related task. Use this method to synchronize your app's state with the state of the
 *						Bluetooth system.
 *
 *  @seealso            CBPeripheralManagerRestoredStateServicesKey;
 *  @seealso            CBPeripheralManagerRestoredStateAdvertisementDataKey;
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict
{
    NSLog(@"peripheralManager:willRestoreState: peripheral:%@ dict: %@", peripheral, dict);
}

/*!
 *  @method peripheralManagerDidStartAdvertising:error:
 *
 *  @param peripheral   The peripheral manager providing this information.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method returns the result of a @link startAdvertising: @/link call. If advertisement could
 *                      not be started, the cause will be detailed in the <i>error</i> parameter.
 *
 */
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"peripheralManagerDidStartAdvertising:error: peripheral:%@ error:%@", peripheral, error);
}

/*!
 *  @method peripheralManager:didAddService:error:
 *
 *  @param peripheral   The peripheral manager providing this information.
 *  @param service      The service that was added to the local database.
 *  @param error        If an error occurred, the cause of the failure.
 *
 *  @discussion         This method returns the result of an @link addService: @/link call. If the service could
 *                      not be published to the local database, the cause will be detailed in the <i>error</i> parameter.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    NSLog(@"peripheralManager:didAddService:error: peripheral:%@ service:%@ error:%@", peripheral, service, error);
}

/*!
 *  @method peripheralManager:central:didSubscribeToCharacteristic:
 *
 *  @param peripheral       The peripheral manager providing this update.
 *  @param central          The central that issued the command.
 *  @param characteristic   The characteristic on which notifications or indications were enabled.
 *
 *  @discussion             This method is invoked when a central configures <i>characteristic</i> to notify or indicate.
 *                          It should be used as a cue to start sending updates as the characteristic value changes.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"peripheralManager:central:didSubscribeToCharacteristic: peripheral:%@ central:%@ characteristic:%@", peripheral, central, characteristic);
    char heartRateData[2]; heartRateData[0] = 0; heartRateData[1] = 60;
    [peripheral updateValue:[NSData dataWithBytes:&heartRateData length:2] forCharacteristic:self.heartRateSensorHeartRateCharacteristic onSubscribedCentrals:nil];
}

/*!
 *  @method peripheralManager:central:didUnsubscribeFromCharacteristic:
 *
 *  @param peripheral       The peripheral manager providing this update.
 *  @param central          The central that issued the command.
 *  @param characteristic   The characteristic on which notifications or indications were disabled.
 *
 *  @discussion             This method is invoked when a central removes notifications/indications from <i>characteristic</i>.
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"peripheralManager:central:didUnsubscribeFromCharacteristic: peripheral:%@ central:%@ characteristic:%@", peripheral, central, characteristic);
}

/*!
 *  @method peripheralManager:didReceiveReadRequest:
 *
 *  @param peripheral   The peripheral manager requesting this information.
 *  @param request      A <code>CBATTRequest</code> object.
 *
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request for a characteristic with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link must be called.
 *
 *  @see                CBATTRequest
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"peripheralManager:didReceiveReadRequest: peripheral:%@ request:%@", peripheral, request);
}

/*!
 *  @method peripheralManager:didReceiveWriteRequests:
 *
 *  @param peripheral   The peripheral manager requesting this information.
 *  @param requests     A list of one or more <code>CBATTRequest</code> objects.
 *
 *  @discussion         This method is invoked when <i>peripheral</i> receives an ATT request or command for one or more characteristics with a dynamic value.
 *                      For every invocation of this method, @link respondToRequest:withResult: @/link should be called exactly once. If <i>requests</i> contains
 *                      multiple requests, they must be treated as an atomic unit. If the execution of one of the requests would cause a failure, the request
 *                      and error reason should be provided to <code>respondToRequest:withResult:</code> and none of the requests should be executed.
 *
 *  @see                CBATTRequest
 *
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"peripheralManager:didReceiveWriteRequests: peripheral:%@ requests:%@", peripheral, requests);
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
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers: peripheral:%@", peripheral);
}

@end
