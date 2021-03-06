/*
 
 Copyright (C) 2009 Id Software, Inc.
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 
 */

#import "wolf3dAppDelegate.h"
#import "EAGLView.h"
#import <AudioToolbox/AudioServices.h>

extern int iphoneStartup();
extern int iphoneShutdown();

char iphoneDocDirectory[1024];
char iphoneAppDirectory[1024];


void vibrateDevice() {
	printf( "vibrate\n" );
	AudioServicesPlaySystemSound( kSystemSoundID_Vibrate );
}

#ifndef IPHONE_APPSTORE
@implementation SplashView
- (id)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.userInteractionEnabled = YES;
    [self setImage:[UIImage imageNamed:@"splashscreen.png"]];
  }
  return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [[event allTouches] anyObject];
	CGPoint temppoint = [touch locationInView:self];
	
	if(temppoint.y > (self.frame.size.height - 100.0f) )
	{
    [[[UIApplication sharedApplication] delegate] startUp];
	}
}

- (void)drawRect:(CGRect)rect {
}

- (void)dealloc {
  [super dealloc];
}

@end
#endif

@implementation wolf3dAppDelegate

@synthesize window;
@synthesize glView;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	application.statusBarHidden = YES;
	application.statusBarOrientation = UIInterfaceOrientationLandscapeLeft;
	
#ifdef IPHONE_APPSTORE
	// get the documents directory, where we will write configs and save games
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	[documentsDirectory getCString: iphoneDocDirectory 
							maxLength: sizeof( iphoneDocDirectory ) - 1
							encoding: NSASCIIStringEncoding ];
	
	// get the app directory, where our data files live
	paths = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSUserDomainMask, YES);
	NSString *appDirectory = documentsDirectory = [paths objectAtIndex:0];
	[appDirectory getCString: iphoneAppDirectory 
							maxLength: sizeof( iphoneAppDirectory ) - 1
							encoding: NSASCIIStringEncoding ];

	// start the flow of accelerometer events
	UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];
	accelerometer.delegate = self;
	accelerometer.updateInterval = 0.01;
  
	// do all the game startup work
	iphoneStartup();  
#else
  sprintf(iphoneAppDirectory, "/Applications/Wolf3D.app/");
  sprintf(iphoneDocDirectory, "/Applications/Wolf3D.app/");

	// do all the game startup work
	iphoneStartup();  
  
	splashView = [[SplashView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 425.0f)];
	[window addSubview: splashView];
  altAds = [[AltAds alloc] initWithFrame:CGRectMake(0.0f, 425.0f, 320.0f, 55.0f) andWindow:window];
  [window makeKeyAndVisible];
#endif
}

#ifndef IPHONE_APPSTORE
- (void)startUp
{
  [splashView removeFromSuperview];
  [altAds removeFromSuperview];
  
  [[UIDevice currentDevice] setOrientation:UIInterfaceOrientationLandscapeLeft];
}
#endif


- (void)applicationWillResignActive:(UIApplication *)application {
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
	iphoneShutdown();
  
#ifndef IPHONE_APPSTORE
  [altAds MobclixEndApplication];
#endif
}



- (void)dealloc {
	[window release];
	[glView release];
	[super dealloc];
}

- (void)restartAccelerometerIfNeeded {
	int Sys_Milliseconds();

	// I have no idea why this seems to happen sometimes...
	if ( Sys_Milliseconds() - lastAccelUpdateMsec > 1000 ) {
		static int count;
		if ( ++count < 100 ) {
			printf( "Restarting accelerometer updates.\n" );
		}
		UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];
		accelerometer.delegate = self;
		accelerometer.updateInterval = 0.01;
	}
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{	
	int Sys_Milliseconds();
	void WolfensteinTilts( float *tilts );
	float acc[4];
	acc[0] = acceleration.x;
	acc[1] = acceleration.y;
	acc[2] = acceleration.z;
	acc[3] = acceleration.timestamp;
	WolfensteinTilts( acc );
	lastAccelUpdateMsec = Sys_Milliseconds();
}

@end



