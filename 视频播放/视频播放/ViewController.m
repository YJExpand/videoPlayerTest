//
//  ViewController.m
//  视频播放
//
//  Created by YJExpand on 16/03/2020.
//  Copyright © 2020 YJExpand. All rights reserved.
//

#import "ViewController.h"

#import "YJMPPlayerCViewController.h"
#import "YJMPPlayerVCViewController.h"
#import "YJAVPlayerViewController.h"
#import "YJAVPlayerVCViewController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong , nonatomic) NSArray<NSString *> *arr;
@end

@implementation ViewController

static NSString *cellId = @"cellId";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.arr = [NSArray arrayWithObjects:@"MPPlayerController -> 使用",@"MPPlayerViewController -> 使用",@"AVPlayer -> 使用",@"AVPlayerViewController -> 使用", nil];
    
}



#pragma mark - <UITableViewDataSource,UITableViewDelegate>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.arr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = self.arr[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIViewController *vc;
    switch (indexPath.row) {
        case 0:  /// MPPlayerController
            vc = [[YJMPPlayerCViewController alloc] init];
            break;
        case 1: /// MPPlayerViewController
            vc = [[YJMPPlayerVCViewController alloc] init];
            break;
        case 2: /// AVPlayer
            vc = [[YJAVPlayerViewController alloc] init];
            break;
        case 3: /// AVPlayerViewController
            vc = [[YJAVPlayerVCViewController alloc] init];
            break;
        default:
            break;
    }
    
    if (!vc) {
        return;
    }
    
    [self.navigationController pushViewController:vc animated:YES];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 54;
}
@end
