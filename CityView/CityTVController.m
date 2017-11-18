//
//  CityTVController.m
//  CityView
//
//  Created by macbook on 11/2/17.
//  Copyright © 2017 Jaminya. All rights reserved.
//

#import "CityTVController.h"

@interface CityTVController ()

@property (nonatomic, strong) NSMutableArray *jsonObjects;
@property (nonatomic, strong) NSCache *imageCache;

@end

@implementation CityTVController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Adjust for overlapping the transparent status bar
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.top = 20;
    [self.tableView setContentInset:contentInset];
    
    _imageCache = [[NSCache alloc] init];
    [self.imageCache setCountLimit:20];

    // Downloaded JSON data
    self.jsonObjects = [NSMutableArray array];
    
}

-(void)viewDidAppear:(BOOL)animated {
    
    // fetch json data on a separate thread
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSURL *url = [NSURL URLWithString:@"http://cdn.jaminya.com/json/cities.json"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSError *jsonError = nil;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        
        if (jsonData != nil) {
            self.jsonObjects = [jsonData objectForKey:@"major_cities"];
            
            // refresh table with text data from downloaded JSON
            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        }
    }); // get_global_queue

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.jsonObjects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdentifier"];
    }

    // Parse city name from downloaded JSON data
    cell.textLabel.text = [[self.jsonObjects objectAtIndex:indexPath.row] objectForKey:@"city"];
   
    // Assign a placeholder image
    cell.imageView.image = [UIImage imageNamed:@"Placeholder.png"];
    
    // Display activity view indicator while downloading flag image
    UIActivityIndicatorView *activityView =
    [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityView startAnimating];
    [cell setAccessoryView:activityView];
    
    // Get image from cache if available
    NSString *imageSlug = [[self.jsonObjects objectAtIndex:indexPath.row] objectForKey:@"slug"];
    NSData *cacheData = [self.imageCache objectForKey:imageSlug];
    UIImage *cachedImage = [UIImage imageWithData:cacheData];
    
    if (cacheData) {
        cell.imageView.image = cachedImage;
        
        // Debug
        NSLog(@"Retrieving cached image: %@",imageSlug);
        
        // Stop activity indicator
        [activityView stopAnimating];
        [activityView setHidesWhenStopped:YES];

    } else {
            // Async fetch state flag
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                NSURL *flagUrl = [NSURL URLWithString:[[self.jsonObjects objectAtIndex:indexPath.row] objectForKey:@"flagUrl"]];
                NSData *data = [NSData dataWithContentsOfURL:flagUrl];
                UIImage *downloadedImage = [[UIImage alloc] initWithData:data];
                
                // Cache downloaded image
                [self.imageCache setObject:data forKey:imageSlug];
                
                // Debug
                NSLog(@"Caching images: %@", imageSlug);

                // Display images on the main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.imageView.image = downloadedImage;
                    
                    // Stop activity indicator
                    [activityView stopAnimating];
                    [activityView setHidesWhenStopped:YES];
                    
                }); // get_main_queue
            }); // get_global_queue
   }
    return cell;
 }


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
