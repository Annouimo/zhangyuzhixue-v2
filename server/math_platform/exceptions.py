from rest_framework.views import exception_handler
from rest_framework_simplejwt.exceptions import AuthenticationFailed, InvalidToken


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is not None:
        # 认证失败（token 过期/无效）→ 40002，让前端触发刷新
        if isinstance(exc, (AuthenticationFailed, InvalidToken)):
            code = 40002
        else:
            code = response.status_code * 100

        detail = response.data

        if isinstance(detail, dict):
            message = list(detail.values())[0]
            if isinstance(message, list):
                message = str(message[0])
            else:
                message = str(message)
        else:
            message = str(detail)

        response.data = {
            'code': code,
            'message': message,
            'data': None,
        }

    return response
