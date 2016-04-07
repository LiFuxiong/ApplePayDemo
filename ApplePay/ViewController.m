//
//  ViewController.m
//  ApplePay
//
//  Created by apple on 6/4/16.
//  Copyright © 2016年 LFX. All rights reserved.
//

#import "ViewController.h"
#import <PassKit/PassKit.h>  //首先导入Apple Pay的库

@interface ViewController ()<PKPaymentAuthorizationViewControllerDelegate> {
    NSMutableArray *summaryItems;
    NSMutableArray *shippingMethods;

}


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //1.判断当前设备是否支持苹果支付
    if(![PKPaymentAuthorizationViewController canMakePayments]) {
        NSLog(@"当前设备不支持Apple Pay");
        //判断是否添加了银行卡（PKPaymentNetworkChinaUnionPay）银联卡，（9.2之后才支持）
    } else if(![PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:@[PKPaymentNetworkChinaUnionPay,PKPaymentNetworkVisa]]) {
        // 创建一个跳转按钮，当用户点击按钮时，跳转到添加银行卡界面
        PKPaymentButton *button = [PKPaymentButton buttonWithType:PKPaymentButtonTypeSetUp style:PKPaymentButtonStyleBlack];
        [button addTarget:self action:@selector(jump) forControlEvents:UIControlEventTouchUpInside];
        button.center = self.view.center;
        [self.view addSubview:button];
    } else {
        // 创建一个购买按钮，当用户点击按钮时，购买一个商品
        PKPaymentButton *button = [PKPaymentButton buttonWithType:PKPaymentButtonTypeBuy style:PKPaymentButtonStyleBlack];
        [button addTarget:self action:@selector(buy) forControlEvents:UIControlEventTouchUpInside];
        button.center = self.view.center;
        [self.view addSubview:button];
    }
}


#pragma mark - 私有方法
//跳转到添加银行卡界面
- (void)jump {
    PKPassLibrary *pl = [[PKPassLibrary alloc] init];
    [pl openPaymentSetup];
}

//购买
- (void)buy {
    NSLog(@"购买商品，开始支付");
    
    //1.创建一个支付请求
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    
    //1.1 配置支付请求
    //1.1.1 配置商家ID
    request.merchantIdentifier = @"merchant.com.applePayBookBuy.demo"; //申请的merchantID
    
    //1.1.2 配置货币代码,以及国家代码
    request.currencyCode = @"CNY";  //RMB的币种代码
    request.countryCode = @"CN";  //国家代码
    
    //1.1.3 配置支持的支付网络
    request.supportedNetworks = @[PKPaymentNetworkVisa,PKPaymentNetworkChinaUnionPay];
    
    //1.1.4 配置商户的处理方式
    request.merchantCapabilities = PKMerchantCapability3DS;////设置支持的交易处理协议，3DS必须支持，EMV为可选，目前国内的话还是使用两者吧
    
    //1.1.5 配置购买的商品列表
    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:@"6000"];
    PKPaymentSummaryItem *itme1 = [PKPaymentSummaryItem summaryItemWithLabel:@" 苹果6s" amount:number];
    
    // 注意：支付列表最后一个，代表汇总
    NSDecimalNumber *totalAmount = [NSDecimalNumber zero];
    totalAmount = [totalAmount decimalNumberByAdding:number];
    //最后这个是支付给谁。哈哈，快支付给我
    PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:@"YXZ" amount:totalAmount];
    //summaryItems为账单列表，类型是 NSMutableArray，这里设置成成员变量，在后续的代理回调中可以进行支付金额的调整。
    summaryItems = [NSMutableArray arrayWithArray:@[itme1,total]];
    request.paymentSummaryItems = summaryItems;
    
    //1.2 配置请求的附加项
    //1.2.1 是否显示发票地址，显示那些选项
    //如果需要邮寄账单可以选择进行设置，默认PKAddressFieldNone(不邮寄账单)
    //楼主感觉账单邮寄地址可以事先让用户选择是否需要，否则会增加客户的输入麻烦度，体验不好，
    request.requiredBillingAddressFields = PKAddressFieldAll;
    
    //1.2.2 是否显示快递地址，显示那些选项
    //送货地址信息，这里设置显示所有，如果需要进行设置，默认PKAddressFieldNone(没有送货地址)
    request.requiredShippingAddressFields = PKAddressFieldAll;
    
    //1.2.3 配置快递方式
    NSDecimalNumber *shippingNumber = [NSDecimalNumber decimalNumberWithString:@"10.0"];
    PKShippingMethod *method = [PKShippingMethod summaryItemWithLabel:@"顺丰" amount:shippingNumber];
    method.identifier = @"顺丰";
    method.detail = @"24小时内送到";
    //shippingMethods为配送方式列表，类型是 NSMutableArray，这里设置成成员变量，在后续的代理回调中可以进行配送方式的调整。
    shippingMethods = [NSMutableArray arrayWithArray:@[method]];
    request.shippingMethods = shippingMethods;
    
    //1.2.3.2 配置快递类型
    request.shippingType = PKShippingTypeStorePickup;
    
    //1.3 添加一些附加数据
    request.applicationData = [@"buyID=1234" dataUsingEncoding:NSUTF8StringEncoding];
    
    //2.用户验证支付授权
    PKPaymentAuthorizationViewController * avc = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
    [self presentViewController:avc animated:YES completion:nil];
    avc.delegate = self; //成为代理，判断用户是否授权

}

#pragma mark
#pragma mark - PKPaymentAuthorizationViewControllerDelegate
#pragma mark - PKPaymentAuthorizationViewControllerDelegate @required
/**
 *  如果用户授权成功，就会调用这个方法
 *
 *  @param controller 授权窗口对象
 *  @param payment    支付对象
 *  @param completion 系统给定的一个回调代码块，我们需要执行这个代码块,来告诉系统当前的支付状态是否成功
 */
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didAuthorizePayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus status))completion {
    //一般在此处，拿到支付信息，发送给服务器处理，处理完毕之后，服务器返回一个状态，告诉客户端，然后由客户端经行处理
    PKPaymentToken *payToken = payment.token; //支付凭据，发给服务端进行验证支付是否真实有效
    PKContact *billingContact = payment.billingContact; //账单信息
    PKContact *shippingContact = payment.shippingContact; //送货信息
    PKShippingMethod *shippingMethod = payment.shippingMethod;  //送货方式
    
    NSLog(@"payToken = %@,billingContact = %@,shippingContact = %@,shippingMethod = %@",payToken,billingContact,shippingContact,shippingMethod);
    //等待服务器返回结果后再进行系统block调用
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //模拟服务器通信
        completion(PKPaymentAuthorizationStatusSuccess);
    });
    
}


/**
 *  当用户授权成功,或者取消授权
 *
 *  @param controller 授权控制器对象
 */
- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    NSLog(@"授权结束");
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - PKPaymentAuthorizationViewControllerDelegate @optional
/**
 *  配送方式回调
 *
 *  @param controller     授权控制器对象
 *  @param shippingMethod 配送方式对象
 *  @param completion     系统给定的一个回调代码块，我们需要执行这个代码块,来告诉系统当前配送方式
 */
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray<PKPaymentSummaryItem *> *summaryItems))completion {
    //配送方式回调，如果需要根据不同的送货方式进行支付金额的调整，比如包邮和付费加速配送，可以实现该代理
    NSString *identifier = shippingMethod.identifier;
    NSString *detail = shippingMethod.detail;
    NSString *label = shippingMethod.label;
    NSDecimalNumber *amount = shippingMethod.amount;
    /*
     PKPaymentSummaryItemTypeFinal,  //支付金额是确定的
     PKPaymentSummaryItemTypePending //支付金额不确定，列如出租车的车费
     */
    PKPaymentSummaryItemType type = shippingMethod.type;
    NSLog(@"identifier = %@,detail = %@,label = %@,amount = %@,type = %ld",identifier,detail,label,amount,type);
    
    PKShippingMethod *oldShippingMethod = [summaryItems objectAtIndex:0];
    PKPaymentSummaryItem *total = [summaryItems lastObject];
    total.amount = [total.amount decimalNumberBySubtracting:oldShippingMethod.amount]; //减去
    total.amount = [total.amount decimalNumberByAdding:shippingMethod.amount];  //加上
    
    [summaryItems replaceObjectAtIndex:0 withObject:shippingMethod];
    [summaryItems replaceObjectAtIndex:1 withObject:total];
    
    completion(PKPaymentAuthorizationStatusSuccess, summaryItems);
}

/**
 *  送货信息回调
 *
 *  @param controller 授权控制器对象
 *  @param contact    送货地址信息对象
 *  @param completion 系统给定的一个回调代码块，我们需要执行这个代码块,来告诉系统当前送货地址信息
 */
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                  didSelectShippingContact:(PKContact *)contact
                                completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray<PKShippingMethod *> *shippingMethods,
                                                     NSArray<PKPaymentSummaryItem *> *summaryItems))completion  {
    //contact送货地址信息，PKContact类型
    NSPersonNameComponents *name = contact.name; //联系人姓名
    CNPostalAddress *postalAddress = contact.postalAddress; //联系人地址
    NSString        *emailAddress = contact.emailAddress; //联系热邮箱
    CNPhoneNumber   *phoneNumber = contact.phoneNumber;  //联系人电话
    NSString        *supplementarySubLocality  = contact.supplementarySubLocality; //补充信息,iOS9.2及以上才有
    NSLog(@"name = %@,postalAddress = %@,emailAddress = %@,phoneNumber = %@,supplementarySubLocality = %@",name,postalAddress,emailAddress,phoneNumber,supplementarySubLocality);
    //送货信息选择回调，如果需要根据送货地址调整送货方式，比如普通地区包邮+极速配送，偏远地区只有付费普通配送，进行支付金额重新计算，可以实现该代理，返回给系统：shippingMethods配送方式，summaryItems账单列表，如果不支持该送货信息返回想要的PKPaymentAuthorizationStatus
    completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, summaryItems);
}


- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                  didSelectShippingAddress:(ABRecordRef)address
                                completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray<PKShippingMethod *> *shippingMethods,
                                                     NSArray<PKPaymentSummaryItem *> *summaryItems))completion {
    //送货地址回调，已弃用
    NSLog(@"苹果已经启用改方法");
    
}



/**
 *  支付银行卡回调
 *
 *  @param controller    授权控制器对象
 *  @param paymentMethod 支付方式对象
 *  @param completion    系统给定的一个回调代码块，我们需要执行这个代码块,来告诉系统当前的银行卡信息
 */
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                    didSelectPaymentMethod:(PKPaymentMethod *)paymentMethod
                                completion:(void (^)(NSArray<PKPaymentSummaryItem *> *summaryItems))completion {
    
    //支付银行卡回调，如果需要根据不同的银行调整付费金额，可以实现该代理
    NSString *displayName = paymentMethod.displayName;
    NSString *network = paymentMethod.network;
    PKPaymentMethodType type = paymentMethod.type;
    NSLog(@"displayName = %@,network = %@,type = %ld",displayName,network,type);
    completion(summaryItems);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
