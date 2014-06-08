//
//  ViewController.m
//  CameraTest
//
//  Created by kakegawa.atsushi on 2014/06/06.
//  Copyright (c) 2013年 kazuhiro.nanko. All rights reserved.
//

#import "ViewController.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import "FormatterUtil.h"

@interface ViewController () 

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic, readonly) NSString *documentDirectory;

@end

@implementation ViewController

#pragma mark - Accessor methods

- (NSString *)documentDirectory
{
#if DEBUG
    NSLog(@"debug_log000");
#endif
    NSArray *documentDirectories =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = nil;
    if (documentDirectories.count > 0) {
        documentDirectory = documentDirectories[0];
    }

    
    return documentDirectory;
}

#pragma mark - Lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];
#if DEBUG
    NSLog(@"debug_log00");
#endif
    //これが宋さんの言っていた「CLLocationManager使うんじゃね？」ってやつか
    //てかこれつかわな位置情報取得できへんしねww
    
    //CLLocationManager使えるんだったら。。。。
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager = [[CLLocationManager alloc] init];
        //GPSの使用を開始する
        [self.locationManager startUpdatingLocation];
    }
    
    
    field =[[UITextField alloc] initWithFrame:CGRectMake(30, 100, 320-60, 200)];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.delegate = self;
    
   
    
    
    [self.view addSubview: field];
}



#pragma mark - UIImagePickerControllerDelegate methods

//メインのメソッドはここで、つどつど情報を取得する為にメソッドを実行している！
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
#if DEBUG
    NSLog(@"debug_log0");
#endif
    // 静止画の参照を取得
    //このinfo[]はどういう意味なんだろう
    //phpの変数における連想は配列みたいな感じ？
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    // メタデータの参照を取得
    //メタデータを一括で取得してきて、その中から必要なデータを使うという形ね。なるほど。
    NSMutableDictionary *metadata = info[UIImagePickerControllerMediaMetadata];
    // Exifの参照を取得
    NSMutableDictionary *exif = metadata[(NSString *)kCGImagePropertyExifDictionary];

    
    exif[(NSString *)kCGImagePropertyExifUserComment] = @"hoge";
    if (self.locationManager) {
        //locationManagerがあれば、位置情報のメタデータを取得しますようというコード
        //GPSDictionaryForLocationはdebug_log5であり、位置情報をいれこんでいるメソッド
        metadata[(NSString *)kCGImagePropertyGPSDictionary] = [self GPSDictionaryForLocation:self.locationManager.location];
        //上記の結果
        //metadata[(NSString *)kCGImagePropertyGPSDictionary] は位置情報を表すNSDataとなる
    }
    
    // Exifなどのメタデータを含む静止画データを作成
    //NSDictionaryを含んだUIイメージの作成
    NSData *imageData = [self createImageDataFromImage:image metaData:metadata];
    
    // 撮影日時からファイル名を生成して、Documentディレクトリに保存
    NSString *fileName = [self fileNameByExif:exif];
    [self storeFileAtDocumentDirectoryForData:imageData fileName:fileName];
    
    
    NSLog(@"meta:%@", [metadata[(NSString *)kCGImagePropertyGPSDictionary] description]);
    field.text = [metadata[(NSString *)kCGImagePropertyGPSDictionary] description];
    

    //詳しくは下記参照
    //http://d.hatena.ne.jp/ntaku/20110110/1294632603
//    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
//    [assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
//        if (error) {
//            NSLog(@"Save image failed. %@", error);
//        }
//    }];
    
    //下記でビューを閉じる
    [self dismissViewControllerAnimated:YES completion:nil];
}




- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Handlers

- (IBAction)buttonDidTouch:(id)sender
{
#if DEBUG
    NSLog(@"debug_log1");
#endif
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    //画像の取得先を指定するプロパティ
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    //モーダル
    [self presentViewController:imagePickerController animated:YES completion:nil];
}


#pragma mark - Private methods
//オリジナルのメソッド
//でも命名が暮らすメソッドのプロジェクトと似ている
//http://dev.classmethod.jp/smartphone/iphone/uiimagepickercontroller-exifgps/
- (NSData *)createImageDataFromImage:(UIImage *)image metaData:(NSDictionary *)metadata
{
#if DEBUG
    NSLog(@"debug_log2");
#endif
    // メタデータ付きの静止画データの格納先を用意する
    NSMutableData *imageData = [NSMutableData new];
    
    // imageDataにjpegで１枚画像を書き込む設定のCGImageDestinationRefを作成する
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, kUTTypeJPEG, 1, NULL);
    
    // 作成したCGImageDestinationRefに静止画データとメタデータを追加する
    CGImageDestinationAddImage(dest, image.CGImage, (__bridge CFDictionaryRef)metadata);
    
    // メタデータ付きの静止画データの作成を実行する
    CGImageDestinationFinalize(dest);
    
    /*
    // CGImageDestinationRefを解放する
    CFRelease(dest);
    */
    
    return imageData;
}






- (void)storeFileAtDocumentDirectoryForData:(NSData *)data fileName:(NSString *)fileName
{
#if DEBUG
    NSLog(@"debug_log3");
#endif
    NSString *documentDirectory = [self documentDirectory];
    if (!documentDirectory) {
        NSLog(@"DocumentDirectory cannot search.");
        return;
    }
    
    NSString *filePath = [documentDirectory stringByAppendingPathComponent:fileName];
    [data writeToFile:filePath atomically:YES];
}


- (NSString *)fileNameByExif:(NSDictionary *)exif
{
#if DEBUG
    NSLog(@"debug_log4");
#endif
    if (!exif) {
        return nil;
    }
    //データを書き出した日
    NSString *dateTimeString = exif[(NSString *)kCGImagePropertyExifDateTimeOriginal];
    NSDate *date = [[FormatterUtil exifDateFormatter] dateFromString:dateTimeString];
    
    NSString *fileName = [[[FormatterUtil fileNameDateFormatter] stringFromDate:date] stringByAppendingPathExtension:@"jpg"];;
    
    return fileName;
}



- (NSDictionary *)GPSDictionaryForLocation:(CLLocation *)location
{
#if DEBUG
    NSLog(@"debug_log5");
#endif
    NSMutableDictionary *gps = [NSMutableDictionary new];

    //日付
    gps[(NSString *)kCGImagePropertyGPSDateStamp] = [[FormatterUtil GPSDateFormatter] stringFromDate:location.timestamp];
    //時間
    gps[(NSString *)kCGImagePropertyGPSTimeStamp] = [[FormatterUtil GPSTimeFormatter] stringFromDate:location.timestamp];
    
    // 緯度
    CGFloat latitude = location.coordinate.latitude;
    NSString *gpsLatitudeRef;
    if (latitude < 0) {
        latitude = -latitude;
        gpsLatitudeRef = @"S";
    } else {
        gpsLatitudeRef = @"N";
    }
    gps[(NSString *)kCGImagePropertyGPSLatitudeRef] = gpsLatitudeRef;
    gps[(NSString *)kCGImagePropertyGPSLatitude] = @(latitude);
    
    // 経度
    CGFloat longitude = location.coordinate.longitude;
    NSString *gpsLongitudeRef;
    if (longitude < 0) {
        longitude = -longitude;
        gpsLongitudeRef = @"W";
    } else {
        gpsLongitudeRef = @"E";
    }
    gps[(NSString *)kCGImagePropertyGPSLongitudeRef] = gpsLongitudeRef;
    gps[(NSString *)kCGImagePropertyGPSLongitude] = @(longitude);
    
    // 標高
    CGFloat altitude = location.altitude;
    if (!isnan(altitude)){
        NSString *gpsAltitudeRef;
        if (altitude < 0) {
            altitude = -altitude;
            gpsAltitudeRef = @"1";
        } else {
            gpsAltitudeRef = @"0";
        }
        gps[(NSString *)kCGImagePropertyGPSAltitudeRef] = gpsAltitudeRef;
        gps[(NSString *)kCGImagePropertyGPSAltitude] = @(altitude);
    }
    
    return gps;
}


/*
-(void)hoge{
    CGImageSourceRef cgImage = CGImageSourceCreateWithData((CFDataRef)photo, nil);
    NSDictionary *metadata = (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(cgImage, 0, nil);
    if (metadata) {
        NSLog(@"%@", [metadata description]);
    } else {
        NSLog(@"no metadata");
    }
    [metadata release];
    CFRelease(cgImage);
}
 */




@end
