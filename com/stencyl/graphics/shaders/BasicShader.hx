package com.stencyl.graphics.shaders;

import com.stencyl.Engine;

class BasicShader
{
	public var multipassParent:BasicShader;
	public var multipassTarget:BasicShader;
	public var model:PostProcess;
	
	public function new()
	{
	}
	
	public function setProperty(name:String, value:Dynamic)
	{
		model.setUniform(name, value);
	}
	
	public function getProperty(name:String):Dynamic
	{
		return model.getUniform(name);
	}
	
	public function tweenProperty(name:String, targetValue:Float, duration:Float = 1, easing:Dynamic = null)
	{
		model.tweenUniform(name, targetValue, duration, easing);
	}
	
	public function enable()
	{
		Engine.engine.addShader(model);
	}
	
	//Doesn't work.
	/*public function enableOnLayer(layerID:Int)
	{
		Engine.engine.clearShaders();
		var layer = Engine.engine.layers.get(layerID);
		layer.addChild(model);
		Engine.engine.addShader(model, false);
	}*/
	
	public function disable()
	{
		Engine.engine.clearShaders();
	}
	
	//Some shaders need to be set to 0.001 to work properly.
	public function setTimeScale(amount:Float)
	{
		model.timeScale = amount;
	}
	
	//Enable only needs to be called on the final shader in the chain.
	public function combine(shader:BasicShader):BasicShader
	{
		multipassTarget = shader;
		shader.multipassParent = this;
		return shader;
	}
}