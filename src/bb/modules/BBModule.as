package bb.modules
{
	import bb.signals.BBSignal;

	import flash.display.Stage;

	/**
	 */
	public class BBModule
	{
		internal var prev:BBModule = null;
		internal var next:BBModule = null;
		internal var prevUpd:BBModule = null;
		internal var nextUpd:BBModule = null;

		//
		internal var i_updateEnable:Boolean = false;

		//
		internal var i_engine:BBModuleEngine;

		// signals
		private var _onInit:BBSignal;
		private var _onReadyToUse:BBSignal;
		private var _onDispose:BBSignal;
		private var _onUpdate:BBSignal;

		/**
		 */
		public function BBModule()
		{
			_onDispose = BBSignal.get(this);
			_onUpdate = BBSignal.get(this);
		}

		/**
		 */
		internal function init():void
		{
			if (_onInit) _onInit.dispatch();
		}

		/**
		 */
		internal function readyToUse():void
		{
			if (_onReadyToUse) _onReadyToUse.dispatch();
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

			_onUpdate.dispatch();
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
		 * Dispatches when module was created and added to engine.
		 * Should use if need initialize some module's data, fields, variables or caching other modules.
		 * This signal goes before onReadyToUse.
		 */
		final public function get onInit():BBSignal
		{
			if (_onInit == null) _onInit = BBSignal.get(this, true);
			return _onInit;
		}

		/**
		 * Module ready to use - module was created, added to system and initialized.
		 * This signal goes after onInit.
		 */
		final public function get onReadyToUse():BBSignal
		{
			if (_onReadyToUse == null) _onReadyToUse = BBSignal.get(this, true);
			return _onReadyToUse;
		}

		/**
		 * Invoke when module have to remove.
		 */
		final public function get onDispose():BBSignal
		{
			return _onDispose;
		}

		/**
		 * When need switch on/off updating in module ('update' method starts/ends is invoked every frame).
		 */
		final public function get onUpdate():BBSignal
		{
			return _onUpdate;
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
		 */
		public function dispose():void
		{
			if (_onDispose == null) return;

			_onDispose.dispatch();
			_onDispose.dispose();
			_onDispose = null;

			_onUpdate.dispose();
			_onUpdate = null;

			if (_onInit) _onInit.dispose();
			_onInit = null;

			if (_onReadyToUse) _onReadyToUse.dispose();
			_onReadyToUse = null;

			//
			i_engine = null;
			i_updateEnable = false;
		}
	}
}
