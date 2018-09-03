#!/usr/bin/python
import json
import sys


def main():

    if len(sys.argv) < 3:
        sys.stderr.write("Missing data\n")
        sys.exit(0)

    try:
        services = json.loads(sys.argv[2])
    except Exception as e:
        sys.stderr.write("Error parsing JSON: %s" % e)
        sys.exit(1)


    backend = sys.argv[1]
    sys.stderr.write("Processing services for backend '%s'" % backend)

    data_output = []
    for i, service in enumerate(services):
        maxconn = 1
        weight = 1
        scheme = 'http'
        sslverify = 'none' # TODO
        #verifyhost = 'verifyhost ' + data['Address']
        verifyhost = ''

        # Service that should only appear in pow backend:
        if ('haproxy.pow=only' in service['Tags'] and backend != 'iri_pow_back'):
            continue

        # Skip non pow services in pow backend
        if (backend == 'iri_pow_back' and
            ('haproxy.pow=true' not in service['Tags'] and
             'haproxy.pow=only' not in service['Tags'])):
            continue

        for tag in service['Tags']:

           # Parse tags
           key, value = tag.split('=')
           if key == 'haproxy.weight':
               weight = value
           elif key == 'haproxy.maxconn':
               maxconn = value
           elif key == 'haproxy.scheme':
               scheme = value
           elif key == 'haproxy.sslverify':
               if value == '0' or value == 'false':
                   sslverify = 'none'
                   verifyhost = ''

        indent = ' ' * 4 if i > 0 else ''
        
        if scheme == 'http':
            data_output.append("%sserver %s %s:%s weight %s maxconn %s resolvers dns resolve-prefer ipv4 check" %
                               (indent, service['ID'], service['Address'], service['Port'], weight, maxconn))
        elif scheme == 'https':
            data_output.append("%sserver %s %s:%s weight %s maxconn %s resolvers dns resolve-prefer ipv4 check ssl verify %s %s" %
                               (indent, service['ID'], service['Address'], service['Port'], weight, maxconn, sslverify, verifyhost))
        
    print("\n".join(data_output))


if __name__ == "__main__":
    main()
