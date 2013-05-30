package bb.modules
{
	import bb.BBModuleEngine;
	import bb.signals.BBSignal;

	import flash.display.Stage;

	/**
	 */
	public class BBModule
	{
		//
		private var _isUpdate:Boolean = false;

		//
		private var _engine:BBModuleEngine;

		// [for internal use]
		private var _z_onSystemInit:BBSignal;

		//
		private var _onInit:BBSignal;

		//
		private var _onReadyToUse:BBSignal;

		//
		private var _onDispose:BBSignal;

		//
		private var _onUpdate:BBSignal;

		/**
		 */
		public function BBModule()
		{
			_z_onSystemInit = BBSignal.get(this, true);
			_z_onSystemInit.add(moduleWasAddedToSystem);

			_onInit = BBSignal.get(this, true);
			_onReadyToUse = BBSignal.get(this, true);
			_onDispose = BBSignal.get(this);
			_onUpdate = BBSignal.get(this);
		}

		/**
		 */
		private function moduleWasAddedToSystem(p_signal:BBSignal):void
		{
			_engine = p_signal.params as BBModuleEngine;

			//
			_z_onSystemInit.dispose();
			_z_onSystemInit = null;
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
		public function set isUpdate(p_val:Boolean):void
		{
			if (_isUpdate == p_val || !isInitialized) return;
			_isUpdate = p_val;

		   _onUpdate.dispatch();
		}

		/**
		 */
		public function get isUpdate():Boolean
		{
			return _isUpdate;
		}

		/**
		 * Methods calls every frame and can be overridden in the children for use.
		 * Method take delta time - time from previous invoke.
		 */
		public function update(p_deltaTime:Number):void
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
		 * @private
		 */
		public function get z_onSystemInit():BBSignal
		{
			return _z_onSystemInit;
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
			_isUpdate = false;
		}
	}
}
