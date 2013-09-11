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
		internal var _updateEnable:Boolean = false;

		//
		internal var _engine:BBModuleEngine;

		private var _onInit:BBSignal;
		private var _onReadyToUse:BBSignal;
		private var _onDispose:BBSignal;
		private var _onUpdate:BBSignal;

		/**
		 */
		public function BBModule()
		{
			_onInit = BBSignal.get(this, true);
			_onReadyToUse = BBSignal.get(this, true);
			_onDispose = BBSignal.get(this);
			_onUpdate = BBSignal.get(this);
		}

		/**
		 * Returns module (which in system) by given class name of needed module.
		 */
		public function getModule(p_moduleClass:Class):BBModule
		{
			return _engine.getModule(p_moduleClass);
		}

		/**
		 * On/off update module every step.
		 * (it is can't be use if module is not initialized)
		 */
		public function set updateEnable(p_val:Boolean):void
		{
			if (_updateEnable == p_val || !isInitialized) return;
			_updateEnable = p_val;

			_onUpdate.dispatch();
		}

		/**
		 */
		public function get updateEnable():Boolean
		{
			return _updateEnable;
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
		public function get stage():Stage
		{
			return _engine.stage;
		}

		/**
		 * Returns module engine.
		 */
		public function get engine():BBModuleEngine
		{
			return _engine;
		}

		/**
		 * Dispatches when module was created and added to engine.
		 * Should use if need initialize some module's data, fields, variables or caching other modules.
		 * This signal goes before onReadyToUse.
		 */
		public function get onInit():BBSignal
		{
			return _onInit;
		}

		/**
		 * Module ready to use - module was created, added to system and initialized.
		 * This signal goes after onInit.
		 */
		public function get onReadyToUse():BBSignal
		{
			return _onReadyToUse;
		}

		/**
		 * Invoke when module have to remove.
		 */
		public function get onDispose():BBSignal
		{
			return _onDispose;
		}

		/**
		 * When need switch on/off updating in module ('update' method starts/ends is invoked every frame).
		 */
		public function get onUpdate():BBSignal
		{
			return _onUpdate;
		}

		/**
		 * Is module initialized (added to system) already.
		 */
		public function get isInitialized():Boolean
		{
			return _engine != null;
		}

		/**
		 * Remove current module from system.
		 */
		public function dispose():void
		{
			_onDispose.dispatch();
			_onDispose.dispose();
			_onDispose = null;

			_onUpdate.dispose();
			_onUpdate = null;

			_onInit.dispose();
			_onInit = null;

			_onReadyToUse.dispose();
			_onReadyToUse = null;

			//
			_engine = null;
			_updateEnable = false;
		}
	}
}
