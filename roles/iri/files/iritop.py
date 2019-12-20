#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import division
import argparse
import re
import sys
import time
import json
import yaml
import random
import base64
from subprocess import check_output
from os import (path, environ, getloadavg, getenv)
from curses import wrapper


__VERSION__ = '0.5.7'

"""\
Simple Iota IRI Node Monitor

This is a simple monitor that runs from the command line.
Typically this is run on the IRI node itself, however,
as soon as the node is allowed to externally expose
getNodeInfo and getNeighbors information, then this tool
can be run from a remote shell as well.

More information:
https://github.com/maeck70/iritop
"""


try:
    import urllib3
except ImportError:
    sys.stderr.write("Missing python urllib3? " +
                     "Install via 'pip install urllib3'"
                     "\n")
    sys.exit(1)

try:
    from blessed import Terminal
except ImportError:
    sys.stderr.write("Missing python blessed package? Install via 'pip install"
                     " blessed'\n")
    sys.exit(1)

try:
    from urlparse import urlparse  # python 2
except ImportError:
    from urllib.parse import urlparse  # python 3


# Url request timeout
URL_TIMEOUT = 5

# Default node URL
NODE = "http://localhost:14265"

# Headers for HTTP call
HEADERS = {'Content-Type': 'application/json',
           'Accept-Charset': 'UTF-8',
           'X-IOTA-API-Version': '1'
           }

USERNAME = ""
PASSWORD = ""
BLINK_DELAY = 0.5
POLL_DELAY = 2
OBSCURE_TOGGLE = 0
ITER = 0
MB = 1024 * 1024
EXIT_MSG = ""
MAX_CYCLES = getenv('MAX_CYCLES', '0')


def parse_args():
    global NODE
    global BLINK_DELAY
    global POLL_DELAY
    global URL_TIMEOUT
    global OBSCURE_TOGGLE
    global USERNAME
    global PASSWORD

    parser = argparse.ArgumentParser(
        description='IRI Top status viewer',
        epilog='Configuration can also be set in yaml formatted file.'
               ' For the configuration keys omit prefix hyphen - or --, and'
               ' replace all other instances of - with _')

    parser.add_argument('--version', '-v', action='version',
                        version='iritop %s' % __VERSION__)

    parser.add_argument('-c', '--config', type=read_config,
                        help="configuration file. Defaults to ~/.iritop",
                        action=LoadFromFile)

    parser.add_argument("-n", "--node", type=url,
                        help="set the node we are connecting with. Default: " +
                              NODE)

    parser.add_argument("-p", "--poll-delay", type=int,
                        help="node poll delay. Default: %ss" % POLL_DELAY)

    parser.add_argument("-b", "--blink-delay", type=float,
                        help="blink delay. Default: %ss" % BLINK_DELAY)

    parser.add_argument("-t", "--url-timeout", type=int,
                        help="URL Timeout. Default: %ss" % URL_TIMEOUT)

    parser.add_argument("-o", "--obscure-address", action='store_true',
                        help="Obscure addresses. Default: Off")

    parser.add_argument("-U", "--username", type=str,
                        help="IRI Username if required.")

    parser.add_argument("-P", "--password", type=str,
                        help="IRI Password if required.")

    parser.add_argument("-d", "--show-domains", action='store_true',
                        help="Display domain names.")

    parser.add_argument("-s", "--sort", type=int,
                        help="Sort column # (-# for reverse sorting)")

    # Get configuration file if exists
    home_dir = path.expanduser("~")
    if path.isfile(home_dir + '/.iritop'):
        sys.argv.extend(['-c', home_dir + '/.iritop'])

    args = parser.parse_args()

    # Check if both username and password are set
    if ((args.username and not args.password) or
            (args.password and not args.username)):
        argparse.ArgumentParser().error(
            "For authentication both username and password are required")

    # Defaults not set by ArgumentParser so that they can
    # be overriden from command line (overrides file)
    if args.blink_delay is None:
        args.blink_delay = BLINK_DELAY
    if args.poll_delay is None:
        args.poll_delay = POLL_DELAY
    if args.obscure_address is None:
        args.obscure_address = OBSCURE_TOGGLE
    if args.node is not None:
        NODE = args.node

    return args


class LoadFromFile(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        for k, v in values.items():
            # Disallow pointing to another config
            if str(k) == 'c' or str(k) == 'config':
                continue

            # Don't override cli args
            if getattr(namespace, k) is not None:
                continue

            # Parse key values as arguments
            k = '--' + k.replace('_', '-')
            parser.parse_args((k, str(v)), namespace=namespace)


letterPairs = [[ord('A'), ord('Z')],
               [ord('a'), ord('z')],
               [ord('0'), ord('9')]]


def scrambleCharacter(c):
    ci = ord(c)

    for lp in letterPairs:
        if lp[0] <= ci <= lp[1]:
            c = chr(random.randint(lp[0], lp[1]))
            break

    return c


def scrambleAddress(addr):
    p1 = addr.find(":")

    addrOut = addr[:p1]
    for c in addr[p1:]:
        addrOut += scrambleCharacter(c)

    return addrOut


def main():
    try:
        args = parse_args()
    except Exception as e:
        sys.stderr.write("Error parsing arguments: %s\n" % e)
        sys.exit(1)

    # Force set locale to ensure blessed term
    # also works when those are missing
    environ['LC_ALL'] = 'en_US.UTF-8'
    environ['LC_CTYPE'] = 'en_US.UTF-8'

    iri_top = IriTop(args)
    wrapper(iri_top.run)


def url(url):
    regex = re.compile(
        r'^(?:http|ftp)s?://'  # http:// or https://
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+'
        r'(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|'  # domain...
        r'localhost|'  # localhost...
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|'  # ...or ipv4
        r'\[?[A-F0-9]*:[A-F0-9:]+\]?)'  # ...or ipv6
        r'(?::([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]'
        r'{2}|655[0-2][0-9]|6553[0-5]))?'  # optional port
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)

    if regex.match(url):
        return url
    else:
        raise argparse.ArgumentTypeError("Invalid node URL")


def read_config(config_file):
    with open(config_file) as fh:
        try:
            data = yaml.load(fh)
        except yaml.parser.ParserError as e:
            raise Exception("Error parsing yaml configuration file '%s': %s" %
                            (config_file, e))
        except Exception as e:
            raise Exception("Error reading configuration file '%s': %s" %
                            (config_file, e))
    return data


def fetch_data(data_to_send, method='POST', status_ok=200):
    global NODE
    global HEADERS
    global URL_TIMEOUT

    http = urllib3.PoolManager()

    try:
        data = json.dumps(data_to_send)
        response = http.request(method,
                                NODE,
                                body=data,
                                timeout=URL_TIMEOUT,
                                headers=HEADERS)
    except Exception as e:
        return None, 'Unknown error: %s' % e

    if response.status == status_ok:
        return json.loads(response.data.decode('utf-8')), None
    else:
        raise Exception("Error response from node: code %d, response: '%s'" %
                        (response.status, response.data))


class IriTop:

    global HEADERES

    def __init__(self, args):

        """
        This instantiates the Terminal class from blessed.
        Terminal type can be forced via TERM environment variable.
        Terminal types supported by the system can normally be
        found via 'find /usr/share/terminfo -type f -printf "%f\n"'
        As an example setting to vt200 ensures no color output.
        """
        self.term = Terminal()

        self.prev = {}
        self.poll_delay = args.poll_delay
        self.blink_delay = args.blink_delay

        """ The commands sent in the query to the node """
        self.commands = [{'command': 'getNeighbors'},
                         {'command': 'getNodeInfo'}]

        self.txkeys = [{'keyshort': 'ad', 'sortkey': '1',
                        'header': 'Neighbor Address',
                        'key': 'neighborAddress', 'col': 0,
                        'sortcolumn': 'address'},
                       {'keyshort': 'at', 'sortkey': '2',
                       'header': 'All tx',
                        'key': 'numberOfAllTransactions', 'col': 3,
                        'sortcolumn': 'numberOfAllTransactions'},
                       {'keyshort': 'nt', 'sortkey': '3',
                       'header': 'New tx',
                        'key': 'numberOfNewTransactions', 'col': 4,
                        'sortcolumn': 'numberOfNewTransactions'},
                       {'keyshort': 'st', 'sortkey': '4',
                       'header': 'Sent tx',
                        'key': 'numberOfSentTransactions', 'col': 5,
                        'sortcolumn': 'numberOfSentTransactions'},
                       {'keyshort': 'rt', 'sortkey': '5',
                       'header': 'Random tx',
                        'key': 'numberOfRandomTransactionRequests', 'col': 6,
                        'sortcolumn': 'numberOfRandomTransactionRequests'},
                       {'keyshort': 'it', 'sortkey': '6',
                       'header': 'Invalid tx',
                        'key': 'numberOfInvalidTransactions', 'col': 7,
                        'sortcolumn': 'numberOfInvalidTransactions'},
                       {'keyshort': 'xt', 'sortkey': '7',
                       'header': 'Stale tx',
                        'key': 'numberOfStaleTransactions', 'col': 8,
                        'sortcolumn': 'numberOfStaleTransactions'}]
        self.randSeed = random.randint(0, 100000)
        self.baseline = dict()
        self.baselineStr = ['Off', 'On']
        self.baselineToggle = 0
        self.obscureAddrToggle = args.obscure_address
        self.width = 0
        self.height = 0
        self.oldheight = 0
        self.oldwidth = 0
        self.incommunicados = 0
        self.localhost = self.set_local_node()
        self.duration_hist = list()
        self.duration = 0
        self.duration_avg = 0
        self.sortmode = False
        self.sortcolumn = None
        self.sortorderlist = ["", " "+u"\u25BC", " "+u"\u25B2"]
        self.sortorder = None
        self.mss_0 = ""
        self.prev_ms_start = 0
        self.show_domains = args.show_domains

        # Initiate column sort
        if args.sort:
            try:
                if args.sort < 0:
                    self.sortorder = self.sortorderlist[1]
                else:
                    self.sortorder = self.sortorderlist[2]
                args.sort = abs(args.sort)
                self.sortcolumn = self.txkeys[args.sort-1]['sortcolumn']
            except IndexError:
                self.sortcolumn = self.txkeys[0]['sortcolumn']

        # Set authentication header if required
        if args.username is not None:
            auth_str = '%s:%s' % (args.username, args.password)
            auth_token = base64.b64encode(auth_str.encode("utf-8"))
            HEADERS['Authorization'] = 'Basic %s' % auth_token.decode()

    @property
    def get_local_ips(self):
        return check_output(['/bin/hostname', '--all-ip-addresses']
                            ).rstrip().split()

    def set_local_node(self):
        local_ips = ['localhost', '127.0.0.1', '::1']
        local_ips.extend(self.get_local_ips)
        if urlparse(NODE.lower()).hostname in local_ips:
            return True
        return False

    def _missing_address(self, neighbor):
        if 'address' not in neighbor or neighbor['address'] == "":
            return True
        return False

    def run(self, stdscr):

        """ Clear the screen on start """
        stdscr.clear()

        """ Counter for number of cycles """
        cycles = 0
        node = None

        print("IRITop connecting to node %s..." % self.showAddress(NODE))

        with self.term.hidden_cursor():
            val = ""
            tlast = 0
            self.hist = {}
            while val.lower() != 'q':

                """ Exit if max cycles specified """
                if int(MAX_CYCLES) != 0 and cycles >= int(MAX_CYCLES):
                    break

                random.seed(self.randSeed)

                val = self.term.inkey(timeout=self.blink_delay)

                # Toggle domain names
                if val.lower() == 'n':
                    self.show_domains = not self.show_domains

                # Sort mode detection
                if val.lower() == 's':
                    if self.sortmode is False:
                        self.sortmode = True
                    else:
                        self.sortmode = False
                if self.sortmode:
                    if self.sortorder is None:
                        self.sortorder = self.sortorderlist[2]
                    keylist = []
                    for k in self.txkeys:
                        keylist.append(k['sortkey'])
                    key = val.lower()
                    if key in keylist:
                        for k in self.txkeys:
                            if key == k['sortkey']:
                                # Toggle sort direction
                                if self.sortcolumn == k['sortcolumn']:
                                    if self.sortorder == self.sortorderlist[2]:
                                        self.sortorder = self.sortorderlist[1]
                                    else:
                                        self.sortorder = self.sortorderlist[2]
                                else:
                                    self.sortorder = self.sortorderlist[2]
                                # Set sort column
                                self.sortcolumn = k['sortcolumn']
                                self.sortmode = False

                self.oldheight, self.oldwidth = self.height, self.width
                self.height, self.width = self.term.height, self.term.width

                time_past = int(time.time()) - tlast
                time_remain = self.poll_delay - time_past
                if time_past > self.poll_delay:

                    if node:
                        self.prev_ms_start = node["milestoneStartIndex"]

                    """ Query data from node, save duration """
                    startTime = int(round(time.time() * 1000))
                    results = [fetch_data(self.commands[i]) for i
                               in range(len(self.commands))]
                    endTime = int(round(time.time() * 1000))
                    self.logDuration(endTime - startTime)

                    """ Increase iteration cycle """
                    cycles += 1

                    """ Process response data """
                    neighbors = None
                    node = None
                    for data, e in results:
                        if e is not None:
                            raise Exception("Error fetching data from node:"
                                            " %s\n" % e)
                        if 'appName' in data.keys():
                            node = data
                        elif 'neighbors' in data.keys():
                            neighbors = data['neighbors']

                    tlast = int(time.time())

                    for neighbor in neighbors:
                        if self._missing_address(neighbor):
                            continue
                        for txkey in self.txkeys[1:]:
                            if txkey['key'] not in neighbor:
                                neighbor[txkey['key']] = 0
                                neighbor[txkey['keyshort']] = 0
                                neighbor['%sDelta' % txkey['key']] = 0

                    # Keep history of tx
                    tx_history = {}
                    for neighbor in neighbors:
                        if self._missing_address(neighbor):
                            continue
                        for txkey in self.txkeys[1:]:
                            self.historizer(txkey['keyshort'],
                                            txkey['key'],
                                            tx_history,
                                            neighbor)
                    self.hist = tx_history

                if val.lower() == 'o':
                    self.obscureAddrToggle = self.obscureAddrToggle ^ 1

                if val.lower() == 'b':
                    for neighbor in neighbors:
                        if self._missing_address(neighbor):
                            continue
                        for txkey in self.txkeys[1:]:
                            self.baseline[self.getBaselineKey(neighbor,
                                          txkey['keyshort'])] = \
                                          neighbor[txkey['key']]
                    self.baselineToggle = self.baselineToggle ^ 1

                if ((self.oldheight != self.height) or
                        (self.oldwidth != self.width)):
                    print(self.term.clear)

                print(self.term.move(0, 0) + self.term.black_on_cyan(
                      "IRITop - Simple IOTA IRI Node Monitor (%s)"
                      .ljust(self.width) % __VERSION__))
                s = str(time_remain) if time_remain > 0 else 'fetch'
                print(self.term.move(0, self.width-6) +
                      self.term.black_on_cyan(s.rjust(6)))

                for neighbor in neighbors:
                    if self._missing_address(neighbor):
                        continue
                    for txkey in self.txkeys[1:]:
                        key = self.getBaselineKey(neighbor, txkey['keyshort'])
                        if key not in self.baseline:
                            self.baseline[key] = 0

                self.show(1, 0, "App Name", node, "appName")
                self.show(2, 0, "App Version", node, "appVersion")

                if "jreFreeMemory" in node:
                    s = self.term.cyan("Free: ") + \
                        str(node["jreFreeMemory"]//MB) + \
                        " Mb  " + \
                        self.term.cyan("Max: ") + \
                        str(node["jreMaxMemory"]//MB) + \
                        " Mb " + \
                        self.term.cyan("Total: ") + \
                        str(node["jreTotalMemory"]//MB) + " Mb   "
                    self.show_string(1, 1, "JRE Memory", s)

                    self.show_histogram(2, 1, "JRE Memory",
                                        node["jreTotalMemory"] -
                                        node["jreFreeMemory"],
                                        node["jreMaxMemory"],
                                        0.8,
                                        span=2)

                ms_start = node["milestoneStartIndex"]
                delta_ms_start = self.prev_ms_start - ms_start
                self.mss_1 = self.mss_0
                self.mss_0 = ("%s" % ms_start) + ("" if delta_ms_start == 0
                                                  else " (%d)" %
                                                  delta_ms_start)
                self.show_string(3, 2, "", " "*16)
                self.show_string(3, 2, "Milestone Start", self.mss_0,
                                 prev=self.mss_1)

                self.show(4, 2, "Milestone Index", node,
                          "latestMilestoneIndex")
                self.show(5, 2, "Milestone Solid", node,
                          "latestSolidSubtangleMilestoneIndex")

                if "jreVersion" in node:
                    self.show(3, 0, "JRE Version", node, "jreVersion")
                self.show(4, 1, "Tips", node, "tips")
                self.show(3, 1, "Tx To Request", node,
                          "transactionsToRequest")

                self.show_string(6, 0, "Node Address", self.showAddress(NODE))

                self.show_string(4, 0, "Baseline",
                                 self.baselineStr[self.baselineToggle])
                self.show_string(5, 0, "Response Time", str(self.duration) +
                                       " ms " + self.term.cyan("Avg: ") +
                                       str(self.duration_avg) + " ms   ")
                neighborCount = "%s" % node['neighbors']
                if self.incommunicados > 0:
                    neighborCount += self.term.red(" / %d " %
                                                   self.incommunicados)
                else:
                    neighborCount += "    "
                self.show_string(6, 2, "Neighbors", neighborCount)

                if self.localhost:
                    self.show_string(5, 1, "Load Average", getloadavg())
                else:
                    self.show_string(5, 1, "Load Average", 'N/A')

                self.show_neighbors(7, neighbors)

    def logDuration(self, duration):
        self.duration = duration
        self.duration_hist.append(duration)
        self.duration_avg = int(sum(self.duration_hist) /
                                len(self.duration_hist))
        # Limit history to the last 5 minutes of calls
        if len(self.duration_hist) > (60*5/self.poll_delay):
            del self.duration_hist[0]

    def showAddress(self, address):
        if self.obscureAddrToggle == 1:
            return scrambleAddress(address)
        return address

    def getBaselineKey(self, neighbor, subkey):
        return "%s:%s" % (neighbor['address'], subkey)

    def historizer(self, txtype, wsid, hd, n):
        nid = "%s-%s" % (n['address'], txtype)
        nidd = "%s-%sd" % (n['address'], txtype)
        c = n[wsid]
        try:
            p = self.hist[nid]
            hd[nid] = c
            if p > 0:
                hd[nidd] = c - p
            else:
                hd[nidd] = 0
        except KeyError:
            hd[nid] = 0
            hd[nidd] = 0

        n["%sDelta" % wsid] = hd[nidd]

    def show(self, row, col, label, dictionary, value):

        x1 = (self.width // 3) * col
        x2 = x1 + 18

        vs = self.term.bright_cyan(str(dictionary[value]))

        # Highlight if no neighbors
        if value == "neighbors" and dictionary[value] == 0:
            vs = self.term.red(str(dictionary[value]))

        # Highlight if latest milestone is out of sync with
        # the solid milestone
        if value == "latestSolidSubtangleMilestoneIndex":
            diff = dictionary["latestSolidSubtangleMilestoneIndex"] - \
              dictionary["latestMilestoneIndex"]

            if diff < 0 and diff >= -2:
                vs = self.term.yellow(
                    str(dictionary[value]) + "*   ")
            elif diff < -2:
                vs = self.term.red(
                        str(dictionary[value]) + " (!)")
            else:
                vs = str(dictionary[value])
            print(self.term.move(row, x2) + " "*(len(vs)+4))

        if value in self.prev and dictionary[value] != self.prev[value]:
            vs = self.term.on_blue(vs)

        print(self.term.move(row, x1) + self.term.cyan(label + ":"))
        print(self.term.move(row, x2) + self.term.bright_cyan(vs))

        self.prev[value] = dictionary[value]

    def show_string(self, row, col, label, value, prev=""):

        x1 = (self.width // 3) * col
        x2 = x1 + 18

        value = str(value)
        if prev != "" and value != prev:
            value = self.term.on_blue(value)

        print(self.term.move(row, x1) + self.term.cyan(label + ":"))
        print(self.term.move(row, x2) +
              self.term.bright_cyan(str(value) + "  "))

    def show_histogram(self, row, col, label, value, value_max,
                       warning_limit=0.8, span=1):

        label_width = 18
        col_width = ((self.width // 3) - label_width) + \
                    ((span - 1) * (self.width // 3))
        x1 = (self.width // 3) * col
        x2 = x1 + label_width
        bw = col_width - 2

        vm = bw
        v = int(value / value_max * bw)
        vl = int(warning_limit * vm)

        mG = v
        mY = 0
        mR = 0
        if v > vl:
            mR = v - vl
            mG = mG - mR
        mB = bw - (mR + mG)

        if value > (value_max * warning_limit):
            mY = mG
            mG = 0

        print(self.term.move(row, x1) + self.term.cyan(label + ":"))
        print(self.term.move(row, x2) +
              self.term.white("[") +
              self.term.green("|" * mG) +
              self.term.yellow("|" * mY) +
              self.term.red("#" * mR) +
              self.term.bright_black("-" * mB) +
              self.term.white("]"))

    def show_neighbors(self, row, neighbors):
        global ITER
        cols = 9
        height, width = self.term.height, self.term.width
        cw = width // cols
        cw1 = width - ((cols - 1) * cw)
        cwl = [0, ]
        for c in range(cols - 1):
            cwl.append(cw1 + (c * cw))

        self.incommunicados = 0
        revso = True if self.sortorder == self.sortorderlist[2] else False

        for k in self.txkeys:
            ch = k['header'] + (' [%s]' % k['sortkey'] if self.sortmode
                                else (self.sortorderlist[1] if revso
                                      else self.sortorderlist[2])
                                if self.sortcolumn == k['sortcolumn']
                                else '')
            ch += "" if k['keyshort'] != 'ad' else " "*(cw*4-len(ch))
            print(self.term.move(row, cwl[k['col']]) +
                  self.term.black_on_green(ch.rjust(cw)))

        row += 1

        # Sort neighbors
        ordered_neighbors = []
        if self.sortcolumn is None:
            self.sortorder = None
            ordered_neighbors = neighbors
        else:
            if self.sortorder is None:
                self.sortorder = self.sortorderlist[0]
            ordered_neighbors = sorted(neighbors,
                                       key=lambda k: k[self.sortcolumn],
                                       reverse=revso)

        # Show Neighbors
        for neighbor in ordered_neighbors:
            if self._missing_address(neighbor):
                continue
            self.show_neighbor(row, neighbor, cwl, cw, height)
            row += 1

        # Blank spare neighbor rows
        for blankrow in range(row, height - 2):
            print(self.term.move(blankrow, 0) + " " * width)

        print(self.term.move(height - 2, 0 * cw) +
              self.term.black_on_cyan(
                    "Q to exit - "
                    "B to reset tx to a zero baseline - "
                    "O to obscure addresses - "
                    "N to toggle domain names - "
                    "S# to sort column".ljust(width)))

        ITER += 1

    def txString(self, neighbor, key, keydelta, keyshort, column_width):
        txcnt = neighbor[key] - (self.baseline[self.getBaselineKey(neighbor,
                                 keyshort)] * self.baselineToggle)
        return ("%d (%d)" % (txcnt, neighbor[keydelta])).rjust(column_width)

    def show_neighbor(self, row, neighbor, column_start_list,
                      column_width, height):
        global ITER

        if self.show_domains is True and 'domain' in neighbor:
            # Domain doesn't contain port, therefore has to be appended
            _address = neighbor['domain'] + ':' \
                                          + neighbor['address'].split(':')[1]
        else:
            _address = neighbor['address']

        neighbor['addr'] = self.showAddress(neighbor['connectionType']
                                            + "://" + _address)

        # Create display string
        for txkey in self.txkeys[1:]:
            neighbor[txkey['keyshort']] = \
                    self.txString(neighbor,
                                  txkey['key'],
                                  '%sDelta' % txkey['key'],
                                  txkey['keyshort'],
                                  column_width)

        # Highlight neighbors that are incommunicado
        incommunicado = False
        if (neighbor['numberOfAllTransactionsDelta'] == 0 and
                ITER > (6 * self.poll_delay)):
            neighbor['addr'] = "(!) " + neighbor['addr']
            incommunicado = True
            self.incommunicados += 1

        # Pad/Trim neighbor address
        ncolw = 3 * (column_width + 1)
        if len(neighbor['addr']) < ncolw:
            # pad
            neighbor['addr'] = neighbor['addr'].ljust(ncolw, ' ')
        elif len(neighbor['addr']) > ncolw:
            # trim
            neighbor['addr'] = neighbor['addr'][0:ncolw]

        value_at = "neighbor-%s-at" % neighbor['address']
        if (value_at in self.prev and
                neighbor['numberOfAllTransactions'] != self.prev[value_at]):
            neighbor['at'] = self.term.cyan(neighbor['at'])

        if neighbor['numberOfInvalidTransactions'] > 0:
            neighbor['it'] = \
                self.term.red(str(neighbor['numberOfInvalidTransactions'])
                              .rjust(column_width))

        # Blink changed value
        for txkey in self.txkeys[1:]:
            neighborkey = "neighbor-%s-%s" % (neighbor['address'],
                                              txkey['keyshort'])
            if (neighborkey in self.prev and
                    neighbor[txkey['key']] != self.prev[neighborkey]):
                neighbor[txkey['keyshort']] = \
                    self.term.cyan(neighbor[txkey['keyshort']])

        # do not display any neighbors crossing the height of the terminal
        if row < height - 2:
            print(self.term.move(row, column_start_list[0]) +
                  (self.term.white(neighbor['addr']) if not incommunicado
                  else self.term.red(neighbor['addr'])))
            for txkey in self.txkeys[1:]:
                print(self.term.move(row, column_start_list[txkey['col']]) +
                      self.term.green(neighbor[txkey['keyshort']]))

        # Store previous value
        for txkey in self.txkeys[1:]:
            neighborkey = "neighbor-%s-%s" % (neighbor['address'],
                                              txkey['keyshort'])
            self.prev[neighborkey] = neighbor[txkey['key']]


if __name__ == '__main__':
    main()
