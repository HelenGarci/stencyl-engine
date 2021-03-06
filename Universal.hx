package;

import openfl.Lib;
import openfl.display.OpenGLRenderer;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.display.StageDisplayState;
import openfl.display.Shape;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;
import openfl.system.Capabilities;
import openfl.ui.Keyboard;
import lime.ui.Window;

import com.stencyl.APIKeys;
import com.stencyl.Config;
import com.stencyl.Engine;
import com.stencyl.Input;
import com.stencyl.graphics.Scale;
import com.stencyl.graphics.ScaleMode;
#if stencyltools
import com.stencyl.utils.ToolsetInterface;
#end
import com.stencyl.utils.Utils;
import haxe.xml.Fast;
import haxe.CallStack;

import haxe.Log in HaxeLog;
import lime.utils.Log in LimeLog;

class Universal extends Sprite 
{
	private static var window:Window;
	public static var logicalWidth = 0.0;
	public static var logicalHeight = 0.0;
	public static var windowWidth = 0.0;
	public static var windowHeight = 0.0;
	
	public var maskLayer:Shape;

	public static function initWindow(window:Window):Void
	{
		Universal.window = window;

		window.stage.align = StageAlign.TOP_LEFT;
		window.stage.scaleMode = StageScaleMode.NO_SCALE;
		
		#if mobile
		window.stage.opaqueBackground = 0x000000;
		#end
	}

	public function new() 
	{
		super();

		addEventListener(Event.ADDED_TO_STAGE, onAdded);
	}
	
	private function onAdded(event:Event):Void 
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAdded);

		initServices();
		
		maskLayer = new Shape();
		initScreen(Config.startInFullScreen);
	}
	
	public function initServices()
	{
		//Newgrounds and other APIs
		
		#if flash
		
		if(APIKeys.newgroundsID != "")
        {
        	com.newgrounds.API.API.connect(root, APIKeys.newgroundsID, APIKeys.newgroundsKey);
        }
        
        #end
	}

	//isFullScreen is used on Web/Desktop for full screen mode
	#if (!flash) @:access(openfl.display.Stage.__setLogicalSize) #end
	public function initScreen(isFullScreen:Bool)
	{
		trace("initScreen");

		#if mobile
		isFullScreen = true;
		#end
		
		#if html5
		isFullScreen = false;
		#end

		stage.displayState = isFullScreen ?
			StageDisplayState.FULL_SCREEN_INTERACTIVE :
			StageDisplayState.NORMAL;
		
		#if !flash
		stage.__setLogicalSize (0, 0);
		#end
		
		#if desktop
		if(!isFullScreen)
		{
			window.resize(Std.int(Config.stageWidth * Config.gameScale), Std.int(Config.stageHeight * Config.gameScale));
		}
		#end

		Lib.current.x = 0;
		Lib.current.y = 0;
		Lib.current.scaleX = 1;
		Lib.current.scaleY = 1;

		x = 0;
		y = 0;
		scaleX = 1;
		scaleY = 1;
	
		Engine.stage = stage;

		//enabled scales
		var scales = new Map<Scale,Bool>();
		for(scale in Config.scales)
		{
			scales.set(scale, true);
		}

		windowWidth = isFullScreen ? stage.fullScreenWidth : Config.stageWidth * Config.gameScale;
		windowHeight = isFullScreen ? stage.fullScreenHeight : Config.stageHeight * Config.gameScale;
		
		trace("Game Width: " + Config.stageWidth);
		trace("Game Height: " + Config.stageHeight);
		trace("Game Scale: " + Config.gameScale);
		trace("Window Width: " + windowWidth);
		trace("Window Height: " + windowHeight);
		trace("FullScreen Width: " + stage.fullScreenWidth);
		trace("FullScreen Height: " + stage.fullScreenHeight);
		trace("Enabled Scales: " + Config.scales);
		trace("Scale Mode: " + Config.scaleMode);
		
		#if ios
		
		var larger = Math.max(windowWidth, windowHeight);
		var smaller = Math.min(windowWidth, windowHeight);
		
		if(smaller == 320 && larger == 480)
		{
			Engine.isStandardIOS = true;
		}
		
		else if(smaller == 640 && larger == 960)
		{
			Engine.isStandardIOS = true;
		}
		
		//iPhone 5, 5s, or iPhone 6 with Display Zoom
		else if(smaller == 640 && larger == 1136)
		{
			Engine.isExtendedIOS = true;
		}	
		
		else if(smaller == 750 && larger == 1334)
		{
			Engine.isIPhone6 = true;
		}	
		
		else if(smaller == 1242 && larger == 2208)
		{
			Engine.isIPhone6Plus = true;
		}
		
		//iPhone 6+ with Display Zoom
		else if(smaller == 1125 && larger == 2001)
		{
			Engine.isIPhone6Plus = true;
		}

		else if(smaller == 1125 && larger == 2436)
		{
			Engine.isIPhoneX = true;
		}
		
		else if(smaller == 1242 && larger >= 2688 && larger <= 2690)
		{
			Engine.isIPhoneXMax = true;
		}
		
		else if(smaller == 828 && larger == 1792)
		{
			Engine.isIPhoneXR = true;
		}
		
		else if
		(
			(smaller == 768 && larger == 1024) ||
			(smaller == 1536 && larger == 2048) ||
			(smaller == 1668 && larger == 2224) ||
			(smaller == 1668 && larger == 2388) ||
			(smaller == 2048 && larger == 2732)
		)
		{
			Engine.isTabletIOS = true;
		}
		
		#end
		
		var theoreticalWindowedScale = getDesiredScale(windowWidth, windowHeight, Config.stageWidth, Config.stageHeight);
		var theoreticalFullscreenScale = getDesiredScale(stage.fullScreenWidth, stage.fullScreenHeight, Config.stageWidth, Config.stageHeight);
		
		var theoreticalScale = Config.forceHiResAssets ? theoreticalFullscreenScale : theoreticalWindowedScale;
		
		//4 scale scheme
		if(theoreticalScale == 4 && scales.exists(Scale._4X))
		{
			Engine.SCALE = 4;
			Engine.IMG_BASE = "4x";
		}
		
		else if(theoreticalScale >= 3 && scales.exists(Scale._3X))
		{
			Engine.SCALE = 3;
			Engine.IMG_BASE = "3x";
		}
		
		else if(theoreticalScale >= 2 && scales.exists(Scale._2X))
		{
			Engine.SCALE = 2;
			Engine.IMG_BASE = "2x";
		}
		
		else if(theoreticalScale >= 1.5 && scales.exists(Scale._1_5X))
		{
			Engine.SCALE = 1.5;
			Engine.IMG_BASE = "1.5x";
		}
		
		else
		{
			Engine.SCALE = 1;
			Engine.IMG_BASE = "1x";
		}
		
		trace("Theoretical Scale: " + theoreticalScale);
		trace("Asset Scale: " + Engine.IMG_BASE);

		//the dimensions of the game screen after being scaled up
		//to the proper asset size.
		var scaledStageWidth = Config.stageWidth * Engine.SCALE;
		var scaledStageHeight = Config.stageHeight * Engine.SCALE;

		//the remaining x/y scale needed to fit the game screen
		//to the edges of the window.
		var fitWidthScale = windowWidth / scaledStageWidth;
		var fitHeightScale = windowHeight / scaledStageHeight;

		if(Config.forceHiResAssets || windowWidth != Config.stageWidth || windowHeight != Config.stageHeight)
		{
			//after the basic assets scale, how do we fill out the rest of the screen?

			//expand the playable area rather than further scaling it
			if(Config.scaleMode == ScaleMode.FULLSCREEN)
			{
				if(Engine.SCALE != theoreticalWindowedScale)
				{
					scaleX = theoreticalWindowedScale / Engine.SCALE;
					scaleY = scaleX;
				}

				//don't do anything
				//stage width/height are already the size of the screen
			}

			//exactly match the game size to the window size for both width and height
			else if(Config.scaleMode == ScaleMode.STRETCH_TO_FIT)
			{
				scaleX = fitWidthScale;
				scaleY = fitHeightScale;
			}
			
			//keeping aspect ration, stretch until either side of the game screen touches the window's edge
			//for "Scale to fit (fullscreen)", the rest of the space is expanded
			else if(Config.scaleMode == ScaleMode.SCALE_TO_FIT_LETTERBOX || Config.scaleMode == ScaleMode.SCALE_TO_FIT_FULLSCREEN)
			{
				scaleX = Math.min(fitWidthScale, fitHeightScale);
				scaleY = scaleX;
			}
			
			//keeping aspect ration, stretch until both sides of the game screen touch the window's edge
			else if(Config.scaleMode == ScaleMode.SCALE_TO_FIT_FILL)
			{
				scaleX = Math.max(fitWidthScale, fitHeightScale);
				scaleY = scaleX;
			}
			
			//no additional scaling
			else if(Config.scaleMode == ScaleMode.NO_SCALING)
			{
				if(Engine.SCALE != theoreticalWindowedScale)
				{
					scaleX = theoreticalWindowedScale / Engine.SCALE;
					scaleY = scaleX;
				}
			}

			if(Config.scaleMode != ScaleMode.SCALE_TO_FIT_FULLSCREEN && Config.scaleMode != ScaleMode.FULLSCREEN)
			{
				x += (windowWidth - scaledStageWidth * scaleX) / 2;
				y += (windowHeight - scaledStageHeight * scaleY) / 2;
			}
		}

		logicalWidth = Config.stageWidth;
		logicalHeight = Config.stageHeight;

		if(isFullScreen && (Config.scaleMode == ScaleMode.SCALE_TO_FIT_FULLSCREEN || Config.scaleMode == ScaleMode.FULLSCREEN))
		{
			logicalWidth = (windowWidth / scaleX) / Engine.SCALE;
			logicalHeight = (windowHeight / scaleY) / Engine.SCALE;

			//bring logical size to the nearest full pixel of the desired value.

			if(Std.int(logicalWidth) != logicalWidth || Std.int(logicalHeight) != logicalHeight)
			{
				logicalWidth = Std.int(logicalWidth);
				logicalHeight = Std.int(logicalHeight);

				scaleX = windowWidth / Engine.SCALE / logicalWidth;
				scaleY = windowHeight / Engine.SCALE / logicalHeight;
			}
		}
		
		Engine.screenScaleX = scaleX;
		Engine.screenScaleY = scaleY;
		
		maskLayer.graphics.clear();
		if(isFullScreen && (Config.scaleMode == ScaleMode.SCALE_TO_FIT_LETTERBOX || Config.scaleMode == ScaleMode.NO_SCALING))
		{
			maskLayer.graphics.beginFill(stage.color);
			maskLayer.graphics.drawRect(-x, -y, windowWidth, y);
			maskLayer.graphics.drawRect(-x, 0, x, scaledStageHeight);
			maskLayer.graphics.drawRect(scaledStageWidth, 0, x, scaledStageHeight);
			maskLayer.graphics.drawRect(-x, scaledStageHeight, windowWidth, y);
			maskLayer.graphics.endFill();
		}
		
		trace("Logical Width: " + logicalWidth);
		trace("Logical Height: " + logicalHeight);
		trace("Scale X: " + scaleX);
		trace("Scale Y: " + scaleY);
	}
	
	private function getDesiredScale(checkWidth:Float, checkHeight:Float, baseWidth:Int, baseHeight:Int):Float
	{
		var x1 = baseWidth;
		var y1 = baseHeight;
		
		var x2 = x1 * 2;
		var y2 = y1 * 2;
		
		var x3 = x1 * 3;
		var y3 = y1 * 3;
		
		var x4 = x2 * 2;
		var y4 = y2 * 2;
		
		var x15 = x3 / 2;
		var y15 = y3 / 2;
		
		
		if(checkWidth >= x4 && checkHeight >= y4)
		{
			return 4;
		}
		
		else if(checkWidth >= x3 && checkHeight >= y3)
		{
			return 3;
		}
		
		else if(checkWidth >= x2 && checkHeight >= y2)
		{
			return 2;
		}
		
		else if(checkWidth >= x15 && checkHeight >= y15)
		{
			return 1.5;
		}
		
		else
		{
			return 1;
		}
	}

	@:access(openfl.display.Stage)
	public function preloaderComplete():Void
	{
		#if flash
		
		new Engine(this);
		
		#else
		
		try {
			
			new Engine(this);
			
		} catch (e:Dynamic) {
			
			#if stencyltools
			if(Config.useGciLogging)
			{
				trace(e #if debug + "\n" + CallStack.toString(CallStack.exceptionStack()) #end);
				ToolsetInterface.preloadedUpdate();
			}
			#end

			stage.__handleError (e);
			
		}

		#end
	}
	
	//for Cppia, don't directly call ApplicationMain functions

	private static var am:Class<Dynamic>;
	private static var oldTrace:Dynamic;

	public static function setupTracing(?forceEnable:Bool = false):Void
	{
		if(oldTrace == null)
			oldTrace = HaxeLog.trace;

		var enable = forceEnable || !Config.releaseMode;
		
		if(enable)
		{
			#if (flash9 || flash10)
			HaxeLog.trace = function(v,?pos) { untyped __global__["trace"]("Stencyl:" + pos.className+"#"+pos.methodName+"("+pos.lineNumber+"):",v); }
			#elseif flash
			HaxeLog.trace = function(v,?pos) { flash.Lib.trace("Stencyl:" + pos.className+"#"+pos.methodName+"("+pos.lineNumber+"): "+v); }
			#else
			HaxeLog.trace = oldTrace;
			#end

			#if stencyltools
			if(Config.useGciLogging)
				HaxeLog.trace = ToolsetInterface.gciTrace;
			#end

			LimeLog.level = VERBOSE;
		}
		else
		{
			HaxeLog.trace = function(v,?pos) { };
			LimeLog.level = NONE;
		}
	}

	public static function reloadGame()
	{
		Reflect.callMethod(am, Reflect.field(am, "reloadGame"), []);
	}

	public static function addReloadListener(reloadListener:Void->Void)
	{
		var reloadListeners:Array<Void->Void> = Reflect.field(am, "reloadListeners");
		reloadListeners.push(reloadListener);
	}
}
