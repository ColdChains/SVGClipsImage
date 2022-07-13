//
//  ViewController.m
//  SVGClipsImage
//
//  Created by lax on 2022/6/21.
//

#import "ViewController.h"
#import "SVGClipsImageView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SVGClipsImageView *zoomView = [[SVGClipsImageView alloc] init];
    zoomView.frame = UIScreen.mainScreen.bounds;
    zoomView.tag = 200;
    [self.view addSubview:zoomView];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(200, 500, 44, 44)];
    [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Clips" forState:UIControlStateNormal];
    [self.view addSubview:button];
    
}

- (void)buttonAction {
    UIImageView *imageView = [self.view viewWithTag:100];
    if (!imageView) {
        imageView = [[UIImageView alloc] init];
        imageView.backgroundColor = [UIColor grayColor];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.tag = 100;
        imageView.frame = CGRectMake(16, 500, 100, 100);
        [self.view addSubview:imageView];
    }
    SVGClipsImageView *clipView = [(SVGClipsImageView *)self.view viewWithTag:200];
    imageView.image = [clipView clipImage];
}

@end
