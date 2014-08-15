package bb.modules
{
	import flash.display.Stage;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

	/**
	 */
	public class BBModule
	{
		/**
		 * Number of frames which need to skip before invoking "update" method.
		 * E.g. skip = 1, every second frame is invoked "update" method.
		 */
		public var skip:uint = 0;

		//
		internal var prev:BBModule = null;
		internal var next:BBModule = null;
		internal var prevUpd:BBModule = null;
		internal var nextUpd:BBModule = null;

		//
		internal var i_skipped:uint = 0;

		//
		internal var i_updateEnable:Boolean = false;

		//
		internal var i_engine:BBModuleEngine;

		/**
		 * Map where key is event name, value - instance of Node with listener method.
		 */
		private var _listeners:Dictionary;

		/**
		 */
		public function BBModule()
		{
			_listeners = new Dictionary();
		}

		/**
		 */
		internal function selfInit():void
		{
			init();
		}

		/**
		 * When module added to engine.
		 * In this state it is possible to init module's values or cache other modules, but can't use it (modules).
		 */
		protected function init():void
		{
			// should be override
		}

		/**
		 */
		internal function selfReady():void
		{
			ready();
		}

		/**
		 * When module completely init and ready to work.
		 * At this step it is possible to use everything.
		 */
		protected function ready():void
		{
			// should be override
		}

		/**
		 * Adds module through another module to engine.
		 */
		public function addModule(p_module:Class, p_immediately:Boolean = false):BBModule
		{
			return i_engine.addModule(p_module, p_immediately);
		}

		/**
		 * Returns module (which in system) by given class name of needed module.
		 */
		public function getModule(p_moduleClass:Class):BBModule
		{
			return i_engine.getModule(p_moduleClass);
		}

		/**
		 * On/off update module every step.
		 * (it is can't be use if module is not initialized)
		 */
		public function set updateEnable(p_val:Boolean):void
		{
			if (i_updateEnable == p_val || !isInitialized) return;
			i_updateEnable = p_val;

			i_engine.updateModule(this);
		}

		/**
		 */
		public function get updateEnable():Boolean
		{
			return i_updateEnable;
		}

		/**
		 * Methods calls every frame and can be overridden in the children for use.
		 * Method take delta time - time from previous invoke.
		 */
		public function update(p_deltaTime:int):void
		{
			//
		}

		/**
		 */
		protected function addListener(p_eventName:String, p_listener:Function, p_senderModuleClass:Class = null):void
		{
			if (_listeners[p_eventName] == null)
			{
				_listeners[p_eventName] = i_engine.addListener(p_eventName, p_listener, this, p_senderModuleClass);
			}
		}

		/**
		 */
		protected function removeListener(p_eventName:String):void
		{
			var node:Node = _listeners[p_eventName];
			if (node) node.unlink();
			delete _listeners[p_eventName];
		}

		/**
		 * Removed all listeners from that module.
		 */
		protected function removeAllListeners():void
		{
			for (var key:String in _listeners)
			{
				removeListener(key);
			}
		}

		/**
		 * Used by engine.
		 */
		internal function clearListenersMap():void
		{
			for (var eventName:String in _listeners)
			{
				delete _listeners[eventName];
			}
		}

		/**
		 * Dispatched event for other modules.
		 */
		protected function dispatch(p_eventName:String, p_param:Object = null):void
		{
			var event:BBEvent = BBEvent.get(p_eventName, this, p_param);
			i_engine.dispatch(event);
			event.dispose();
		}

		/**
		 */
		final public function get stage():Stage
		{
			return i_engine.stage;
		}

		/**
		 * Returns module engine.
		 */
		final public function get engine():BBModuleEngine
		{
			return i_engine;
		}

		/**
		 * Is module initialized (added to system) already.
		 */
		final public function get isInitialized():Boolean
		{
			return i_engine != null;
		}

		/**
		 * Remove current module from system.
		 * Also removed all listeners of module.
		 */
		public function dispose():void
		{
			if (i_engine == null) return;

			removeAllListeners();
			i_engine.removeModule(this);

			//
			i_engine = null;
			_listeners = null;
			i_updateEnable = false;
		}

		/**
		 */
		public function toString():String
		{
			return "Module - [name:" + getQualifiedClassName(this) + "], [initialized: " + isInitialized + "], [update: " + updateEnable + "], [skip: " + skip + "]";
		}
	}
}
