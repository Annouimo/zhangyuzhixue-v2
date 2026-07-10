from rest_framework.views import exception_handler


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is not None:
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
