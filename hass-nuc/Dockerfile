ARG BUILD_VERSION
FROM homeassistant/intel-nuc-homeassistant:$BUILD_VERSION

RUN pip install srp && apk --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ add android-tools

# Run Home Assistant
WORKDIR /usr/src/app
CMD [ "python3", "-m", "homeassistant", "--config", "/config" ]