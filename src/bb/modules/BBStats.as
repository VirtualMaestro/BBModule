package bb.modules
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;

	/**
	 * ...
	 * @author VirtualMaestro
	 */
	internal class BBStats extends Sprite
	{
		private var _maxMem:Number = 0;
		private var _loopTimeCollector:int = 0;
		private var _iterator:int = 0;
		private var _fpsCollector:Number = 0;

		private var _output:TextField;

		private var _deepIndex:int;

		/**
		 */
		public function BBStats(p_backgroundColor:uint = 0x000000, p_textColor:uint = 0xffffff)
		{
			super();

			//
			mouseEnabled = false;
			mouseEnabled = false;

			// init text output
			initOutput();

			//
			setStyle(p_backgroundColor, p_textColor);

			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}

		/**
		 */
		private function addedToStageHandler(p_event:Event):void
		{
			_deepIndex = stage.getChildIndex(this);
		}

		/**
		 * p_frequencyUpdate - how often data is updated (in milliseconds). By default half second.
		 */
		public function update(p_prevTime:int, p_currentTime:int, p_codeExecutionTime:int, p_frequencyUpdate:int = 500):void
		{
			var fullLoopTime:int = p_currentTime - p_prevTime;
			_loopTimeCollector += fullLoopTime;
			_fpsCollector += 1000.0 / fullLoopTime;
			_iterator++;

			//
			if (_loopTimeCollector >= p_frequencyUpdate)
			{
				var mKb:int = System.totalMemory * 0.0001;
				var memMb:Number = mKb / 100;
				if (memMb > _maxMem) _maxMem = memMb;

				_output.text = "FPS: " + int((_fpsCollector / _iterator) + 0.5) + " / " + stage.frameRate + "\n" +
						"MS: " + int(Number(_loopTimeCollector) / _iterator + 0.5) + " ms \n" +
						"Mem: " + memMb + "\n" +
						"Max mem: " + _maxMem + "\n" +
						"Code FPS: " + int(1000 / (p_codeExecutionTime > 1 ? p_codeExecutionTime : 1)) + "\n" +
						"Code exec: " + p_codeExecutionTime + "ms";

				_loopTimeCollector = 0;
				_fpsCollector = 0;
				_iterator = 0;

				// put on top of screen
				var stageNumChildren:int = stage.numChildren - 1;
				if (_deepIndex < stageNumChildren)
				{
					stage.addChildAt(this, stageNumChildren);
					_deepIndex = stageNumChildren;
				}
			}
		}

		/**
		 */
		public function setStyle(p_backgroundColor:uint = 0x000000, p_textColor:uint = 0xffffff):void
		{
			initBackground(p_backgroundColor);

			var tf:TextFormat = _output.defaultTextFormat;
			tf.color = p_textColor;
			_output.defaultTextFormat = tf;
		}

		/**
		 */
		private function initBackground(p_color:uint):void
		{
			graphics.beginFill(p_color);
			graphics.drawRect(0, 0, 110, 100);
			graphics.endFill();
		}

		/**
		 */
		private function initOutput():void
		{
			_output = new TextField();
			_output.defaultTextFormat = new TextFormat("Arial", 12, 0xffffff, true);
			_output.width = 110;
			_output.selectable = false;
			_output.x = 1;
			_output.y = 1;
			addChild(_output);
		}
	}
}