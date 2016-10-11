FROM python:3.3

RUN wget -O- http://xyne.archlinux.ca/projects/python3-threaded_servers/src/python3-threaded_servers-2016.tar.xz | tar Jxf - -C /tmp
RUN wget -O- http://xyne.archlinux.ca/projects/quickserve/src/quickserve-2013.5.tar.xz | tar Jxf - -C /tmp
WORKDIR /tmp/python3-threaded_servers-2016
RUN python3 setup.py install --prefix=/usr/local --optimize=1
WORKDIR /tmp/quickserve-2013.5
RUN install -Dm755 quickserve /usr/local/bin/quickserve

ENTRYPOINT ["/usr/local/bin/quickserve"]
