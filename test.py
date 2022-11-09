#!/usr/bin/env python3
import subprocess
import uuid
import re
from pathlib import Path

class DefaultValues(object):
    version_update_file = "version_updater.json"
    project = "default"


class CommonFunctions(DefaultValues):
    def run_code(self, code, everything=False, script=False, verbose=False):
        if script:
            tmpfilename = "/tmp/" + str(uuid.uuid4())[:8] + ".sh"
            if verbose:
                print("making ", tmpfilename)
            code = code + "\nrm -vf " + tmpfilename
            with open(tmpfilename, "w") as f:
                f.write(code)
            MyOut = subprocess.Popen(
                ["bash", tmpfilename], stdout=subprocess.PIPE, stderr=subprocess.STDOUT
            )
        else:
            if verbose:
                print(code)
            MyOut = subprocess.Popen(
                code, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
            )
        stdout, stderr = MyOut.communicate()
        if verbose:
            if MyOut.returncode != 0:
                print(
                    "cmd {0} return code {1}".format(" ".join(code), MyOut.returncode)
                )
            if stderr is not None:
                print("stderr")
                print(stderr)
        if everything:
            return {"out": stdout, "err": stderr, "obj": MyOut}
        else:
            return stdout.decode()

    def volsh(self, cmd):
        # return "test"
        return self.run_code(["./vols.sh"] + cmd, everything=True)

["new","-v","example"]
# check Path("./vols.conf").exists()
["up"]
["down","-f"]
class TestMonkey(object):
    def __init__(self):
        self.cf = CommonFunctions()

    def vols(self,cmds):
        return self.cf.volsh(cmds)

    def process_obj(self, obj):
        result = " ".join(obj["obj"].args) + "\n"
        if obj["out"] and obj["obj"].returncode == 0:
            result += obj["out"].decode() + "\n"
        if obj["err"]:
            result += obj["out"].decode()+" "+obj["err"].decode()+" rc:"+str(obj["obj"].returncode) + "\n"
        return result

    def a_new_test(self):
        return self.vols(["new","-v","example"])

    def b_up_file_test(self):
        return self.vols(["up"])

    def c_down_test(self):
        return self.vols(["down","-f"])

    def d_rm_file_test(self):
        return self.cf.run_code(["rm","-f","vols.conf"], everything=True)

    def e_up_cli_test(self):
        return self.vols(["up","-v","examplea"])

    def f_down_test(self):
        return self.vols(["down","-f","-v","examplea"])

    def filter_tests(self, var):
        prog = re.compile(".*_test$")
        result = prog.match(var)
        return result

    def __call__(self):
        results = filter(self.filter_tests,dir(self))
        for result in results:
            func = getattr(self, result)
            res = func()
            print(self.process_obj(res))
            
TestMonkey()()
