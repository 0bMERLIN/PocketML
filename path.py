
from kivy import platform

storage_path = None
if platform == "android":
    from android.storage import app_storage_path  # type: ignore
    from android import mActivity  # type: ignore
    from android.permissions import request_permissions, Permission  # type: ignore

    request_permissions(
        [Permission.WRITE_EXTERNAL_STORAGE, Permission.READ_EXTERNAL_STORAGE]
    )

    context = mActivity.getApplicationContext()
    result = context.getExternalFilesDir(None)  # don't forget the argument
    if result:
        storage_path = str(result.toString())
    else:
        storage_path = app_storage_path()  # NOT SECURE
    print("STORAGE:", storage_path)

else:
    storage_path = "examples/"
    print("STORAGE:", storage_path)
