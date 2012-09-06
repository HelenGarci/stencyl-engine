package com.stencyl.graphics.transitions;

import nme.geom.Rectangle;
import nme.display.Sprite;
import nme.display.Graphics;
import nme.display.BitmapData;
import nme.display.Shape;

import com.stencyl.Engine;

import com.eclecticdesignstudio.motion.Actuate;
import com.eclecticdesignstudio.motion.easing.Linear;


class BlindsTransition extends Transition
{
	public var color:Int;
	public var numBlinds:Int;
		
	//needs to be public so that it can be tweened
	public var blindWidth:Float;		
	
	private var beginBlindWidth:Float;
	private var endBlindWidth:Float;	
	
	private var blindRect:Rectangle;
	private var rect:Shape;
	private var graphics:Graphics;
	
	public function new(direction:String, duration:Float, numBlinds:Int = 10, color:Int) 
	{
		super(duration);
			
		this.color = color;
		this.direction = direction;
		this.numBlinds = numBlinds;
		
		if(direction == Transition.IN)
		{
			beginBlindWidth = Engine.screenWidth / numBlinds; 
			endBlindWidth = 0;
		}
		else if(direction == Transition.OUT)
		{
			beginBlindWidth = 0;
			endBlindWidth = Engine.screenWidth / numBlinds;
		}
		else
		{
			trace("Invalid transition direction: " + direction);
			complete = true;
		}
	}
	
	override public function start()
	{
		active = true;
		
		blindRect = new Rectangle(0, 0, beginBlindWidth, Engine.screenHeight);
		blindWidth = beginBlindWidth;
		
		rect = new Shape();
		graphics = rect.graphics;
		
		if (direction == Transition.IN)
		{
			graphics.beginFill(color);
			graphics.drawRect(0, 0, Engine.screenWidth, Engine.screenHeight);
			graphics.endFill();
		}		
		
		Engine.engine.transitionLayer.addChild(rect);
		
		Actuate.tween(this, duration, { blindWidth:endBlindWidth} ).ease(Linear.easeNone).onComplete(stop);
	}
	
	override public function draw(g:Graphics)
	{
		graphics.clear();
		graphics.beginFill(color);
		
		blindRect.x = 0;
		blindRect.width = blindWidth;
		
		if(direction == Transition.IN)
		{
			blindRect.x += (Engine.screenWidth / numBlinds - blindWidth);
		}			
		
		for(i in 0...numBlinds)
		{
			
			graphics.drawRect(blindRect.x, blindRect.y, blindRect.width, blindRect.height);
			blindRect.x += Engine.screenWidth / numBlinds;
		}
		
		graphics.endFill();
	}
	
	override public function cleanup()
	{		
		if(rect != null)
		{
			Engine.engine.transitionLayer.removeChild(rect);
			rect = null;
		}
	}
}