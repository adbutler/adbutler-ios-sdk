//
//  ViewController.m
//  ObjC Sample
//
//  Created by Ryuichi Saito on 11/8/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

@import AdButler;
#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)requestPlacementTapped:(id)sender {
    PlacementRequestConfig *config = [[PlacementRequestConfig alloc] initWithAccountId:153105 zoneId:214764 width:300 height:250 keywords:@[] click:nil];
    [AdButler requestPlacementWith:config success:^(NSString * _Nonnull status, NSArray<Placement *> * _Nonnull placements) {
        NSLog(@"status: %@\nplacements: %@", status, placements);
    } failure:^(NSNumber * _Nullable statusCode, NSString * _Nullable responseBody, NSError * _Nullable error) {
        // :)
    }];
}

- (IBAction)requestPlacementsTapped:(id)sender {
    PlacementRequestConfig *config = [[PlacementRequestConfig alloc] initWithAccountId:153105 zoneId:214764 width:300 height:250 keywords:@[] click:nil];
    NSArray *configs = @[config, config, config];
    [AdButler requestPlacementsWith:configs success:^(NSString * _Nonnull status, NSArray<Placement *> * _Nonnull placements) {
        NSLog(@"status: %@\nplacements: %@", status, placements);
    } failure:^(NSNumber * _Nullable statusCode, NSString * _Nullable responseBody, NSError * _Nullable error) {
        // :)
    }];
    
}

@end
