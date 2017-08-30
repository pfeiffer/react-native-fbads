//
//  CTKInterstitialAdManager.m
//  rn-fbads
//
//  Created by Michał Grabowski on 29/09/2016.
//  Copyright © 2016 callstack. All rights reserved.
//

#import "CTKInterstitialAdManager.h"
#import <React/RCTUtils.h>
@import FBAudienceNetwork;

@interface CTKInterstitialAdManager () <FBInterstitialAdDelegate>

@property (nonatomic, strong) RCTPromiseResolveBlock resolve;
@property (nonatomic, strong) RCTPromiseRejectBlock reject;
@property (nonatomic, strong) FBInterstitialAd *interstitialAd;
@property (nonatomic) bool didClick;

@end

@implementation CTKInterstitialAdManager

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(
  showAd:(NSString *)placementId
  resolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject
) {
  if (_resolve != nil && _reject != nil) {
    reject(@"E_FAILED_TO_SHOW", @"Only one `showAd` can be called at once", nil);
    return;
  }
  
  _resolve = resolve;
  _reject = reject;
  
  _interstitialAd = [[FBInterstitialAd alloc] initWithPlacementID:placementId];
  _interstitialAd.delegate = self;
  [_interstitialAd loadAd];
}

#pragma mark - FBInterstitialAdDelegate

- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
  // To support displaying modally, we recurse through all presented controllers
  // to find the top-most controller to display the video controller modally from:
  UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
  UIViewController *rootViewController = window.rootViewController;
  UIViewController *topViewController = [self topViewController:rootViewController];
    
  [interstitialAd showAdFromRootViewController:topViewController];
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController) {
        return [self topViewController:rootViewController.presentedViewController];
    }
    return rootViewController;
}

- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
  _reject(@"E_FAILED_TO_LOAD", [error localizedDescription], error);
  
  [self cleanUpPromise];
}

- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
  _didClick = true;
}

- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
  _resolve(@(_didClick));
  
  [self cleanUpPromise];
}

- (void)cleanUpPromise {
  _reject = nil;
  _resolve = nil;
  _interstitialAd = nil;
  _didClick = false;
}

@end
