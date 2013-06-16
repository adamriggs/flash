﻿package away3d.materials
{
    import away3d.arcane;
    import away3d.containers.View3D;
    import away3d.core.base.*;
    import away3d.core.utils.*;
    import away3d.events.*;
    
    import flash.display.BitmapData;
    import flash.display.BlendMode;
    import flash.display.Sprite;
    import flash.geom.ColorTransform;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
	
	use namespace arcane;
	
	/**
	 * Animated movie material.
	 */
    public class MovieMaterial extends TransformBitmapMaterial
    {
		/** @private */
        arcane override function updateMaterial(source:Object3D, view:View3D):void
        {
        	super.updateMaterial(source, view);
        	
        	if (autoUpdate)
                update();
            
            _session = source.session;
            if (interactive) {
            	//check to see if interactiveLayer is initialised
                if (!view._interactiveLayer.contains(movie)) {
            		view._interactiveLayer.addChild(movie);
            		resetInteractiveLayer();
            		source.addOnMouseOver(onMouseOver);
            		source.addOnMouseOut(onMouseOut);
                }
            	
            } else if (view._interactiveLayer.contains(movie)) {
            	view._interactiveLayer.removeChild(movie);
            	source.removeOnMouseOver(onMouseOver);
            	source.removeOnMouseOut(onMouseOut);
            }
        }
        
    	private var _movie:Sprite;
        private var _colTransform:ColorTransform;
        private var _bMode:String;
		private var x:Number;
		private var y:Number;
		private var t:Matrix;
		public var extras:Object;
		
		private function onMouseOver(event:MouseEvent3D):void
		{
			if (event.material == this) {
				event.object.addOnMouseMove(onMouseMove);
				onMouseMove(event);
			}
		}
		
		private function onMouseOut(event:MouseEvent3D):void
		{
			if (event.material == this) {
				event.object.removeOnMouseMove(onMouseMove);
				resetInteractiveLayer();
			}
			
		}
		
		private function onMouseMove(event:MouseEvent3D):void
		{
			x = event.uv.u*_renderBitmap.width;
			y = (1 - event.uv.v)*_renderBitmap.height;
			
			if (_transform) {
				t = _transform.clone();
				t.invert();
				movie.x = event.screenX - x*t.a - y*t.c - t.tx;
				movie.y = event.screenY - x*t.b - y*t.d - t.ty;
			} else {
				movie.x = event.screenX - x;
				movie.y = event.screenY - y;
			}
		}
 		
 		private function resetInteractiveLayer():void
 		{
 			movie.x = -10000;
 			movie.y = -10000;
 		}
 		
        /** @private */
		protected override function updateRenderBitmap():void
        {
        	
        }
        
        /**
        * Defines the transparent property of the texture bitmap created from the movie
        * 
        * @see movie
        */
        public var transparent:Boolean;
        
        /**
        * Indicates whether the texture bitmap is updated on every frame
        */
        public var autoUpdate:Boolean;
        
        /**
        * Indicates whether the material will pass mouse interaction through to the movieclip
        */
        public var interactive:Boolean;
        
		/**
		 * @inheritDoc
		 */
        public override function get width():Number
        {
            return _renderBitmap.width;
        }
        
		/**
		 * @inheritDoc
		 */
        public override function get height():Number
        {
            return _renderBitmap.height;
        }
        
        /**
        * Defines the movieclip used for rendering the material
        */
        public function get movie():Sprite
        {
        	return _movie;
        }
        
        public function set movie(val:Sprite):void
        {
        	if (_movie == val)
        		return;
        	
        	if (_movie && _movie.parent)
        		_movie.parent.removeChild(_movie);
        	
        	_movie = val;
        }
        
		/**
		 * Creates a new <code>BitmapMaterial</code> object.
		 * 
		 * @param	movie				The sprite object to be used as the material's texture.
		 * @param	init	[optional]	An initialisation object for specifying default instance properties.
		 */
        public function MovieMaterial(movie:Sprite, init:Object = null)
        {
            ini = Init.parse(init);
            transparent = ini.getBoolean("transparent", true);
            autoUpdate = ini.getBoolean("autoUpdate", true);
            interactive = ini.getBoolean("interactive", false);
			
			_movie = movie;
			
			_lockW = ini.getNumber("lockW", movie.width);
			_lockH = ini.getNumber("lockH", movie.height);
            _bitmap = new BitmapData(Math.max(1,_lockW), Math.max(1,_lockH), transparent, (transparent) ? 0x00ffffff : 0);
            
        	super(_bitmap, ini);
        }
        
		/**
		 * Updates the texture bitmap with the current frame of the movieclip object
		 * 
		 * @see movie
		 */
        public function update():void
        {
			
			if(_renderBitmap != null){
				
				notifyMaterialUpdate();
				
				var rectsource:Rectangle = (_clipRect == null || !rendered)? _renderBitmap.rect : _clipRect;
				
				if (transparent )
					_renderBitmap.fillRect(rectsource, 0x00FFFFFF);
					
				if (_alpha != 1 || _color != 0xFFFFFF)
					_colTransform = _colorTransform;
				else
					_colTransform = movie.transform.colorTransform;
					
				if (_blendMode != BlendMode.NORMAL)
					_bMode = _blendMode;
				else
					_bMode = movie.blendMode;
			
					_renderBitmap.draw(movie, new Matrix(movie.scaleX, 0, 0, movie.scaleY), _colTransform, _bMode, rectsource );
				
				if(!rendered) rendered = true;

			}
			 
        }
		
		private var _clipRect:Rectangle;
		private var _lockW:Number;
		private var _lockH:Number;
		
		private var rendered:Boolean;
		/**
		* A Rectangle object that defines the area of the source to draw. If null, no clipping occurs and the entire source object is drawn. Default is null.
		* 
		* @param clipRect	 A Rectangle object that defines the area of the source to draw. If null, no clipping occurs and the entire source object is drawn.
		*/
		public function set clipRect (rect:Rectangle):void
        {
			_clipRect = rect;
		}
		
		public function get clipRect ():Rectangle
        {
			return _clipRect;
		}
		
		/**
		*A Number to lock the height of the draw region other than the source movieclip source. Default is the movieclip height.
		* 
		* @param width	 A Number to lock the height of the draw region other than the source movieclip source.
		*/
		public function set lockW (width:Number):void
        {
			_lockW = (!isNaN(width) && width> 1)? width : _lockW;
			if(_renderBitmap != null){
				_bitmap.dispose();
				_renderBitmap.dispose();
				_bitmap = new BitmapData(Math.max(1,_lockW), Math.max(1,_lockH), transparent, (transparent) ? 0x00ffffff : 0);
				_renderBitmap = _bitmap.clone();
				update();
			}
		}
		
		public function get lockW ():Number
        {
			return _lockW;
		}
		
		/**
		*A Number to lock the height of the draw region other than the source movieclip source. Default is the movieclip height.
		* 
		* @param height	 A Number to lock the height of the draw region other than the source movieclip source.
		*/
		public function set lockH (height:Number):void
        {
			_lockH = (!isNaN(height) && height> 1)? height : _lockH;
			if(_renderBitmap != null){
				_bitmap.dispose();
				_renderBitmap.dispose();
				_bitmap = new BitmapData(Math.max(1,_lockW), Math.max(1,_lockH), transparent, (transparent) ? 0x00ffffff : 0);
				_renderBitmap = _bitmap.clone();
				update();
			}
		}
		
		public function get lockH ():Number
        {
			return _lockH;
		}
		
    }
}