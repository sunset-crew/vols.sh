#!/usr/bin/env python3
import subprocess
import uuid
import re
from pathlib import Path

class DefaultValues(object):
    project = "vol.sh"


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


class TestMonkey(object):
    def __init__(self):
        self.cf = CommonFunctions()

    def vols(self,cmds):
        return self.cf.run_code(["./vols.sh"] + cmds, everything=True)

    def process_obj(self, obj):
        out = ""
        if obj["out"]:
            out = obj["out"].decode()
        err = ""
        if obj["err"]:
            out = obj["err"].decode()
        result = " ".join(obj["obj"].args) + "\n"
        if obj["out"] and obj["obj"].returncode == 0:
            result += out + "rc:"+str(obj["obj"].returncode) + "\n"
        if obj["err"] or obj["obj"].returncode != 0:
            result += out+" "+err+"rc:"+str(obj["obj"].returncode) + "\n"
        return result

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

    # Edit after this line
    # make sure to keep the alpha indexing
    # also, this is bash testing
    # so everything needs to be a derivative run_code

    def a_create_new_vols_conf_test(self):
        """
        Create new vols.conf
        """
        return self.vols(["new","-v","example"])

    def b_check_vols_conf_created_test(self):
        """
        Check vols.conf exists
        """
        return self.cf.run_code(["stat","vols.conf"], everything=True)

    def c_up_vols_conf_test(self):
        """
        Mount Docker External Volumes with vols.conf
        """
        return self.vols(["up"])

    def d_down_vols_conf_test(self):
        """
        UnMount Docker External Volumes with vols.conf
        """
        return self.vols(["down","-f"])

    def e_rm_vols_conf_test(self):
        """
        Removes vols.conf
        """
        return self.cf.run_code(["rm","-f","vols.conf"], everything=True)

    def f_up_imperative_test(self):
        """
        Mount Docker External Volumes with -v <volume>
        """
        return self.vols(["up","-v","examplea"])

    def g_down_imperative_test(self):
        """
        UnMount Docker External Volumes with -v <volume>
        """
        return self.vols(["down","-f","-v","examplea"])

    def h_check_file_test(self):
        """
        Test Fail Check for non-existent vols.conf
        """
        return self.cf.run_code(["stat","vols.conf"], everything=True)


if __name__ == "__main__":
    TestMonkey()()
