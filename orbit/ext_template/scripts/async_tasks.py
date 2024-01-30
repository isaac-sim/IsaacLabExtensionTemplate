import omni.ext

class MyExt(omni.ext.IExt):
   """My extension application."""

   def on_startup(self, ext_id):
      """Called when the extension is loaded."""
      pass

   def on_shutdown(self):
      """Called when the extension is unloaded.

      It releases all references to the extension and cleans up any resources.
      """
      pass
