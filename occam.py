import os
import sys
import json
import subprocess
import shlex
import base64

class Occam:
  """
  Represents the OCCAM helper library for artifacts.
  """

  class Object:
    def lookup(self, type, index, data=None):
      if data is None:
        data = self._major_object

      if data.get('type') == type and data.get('index') == index:
        return data
      else:
        for input in data.get('input', []):
          ret = self.lookup(type, index, input)
          if not ret is None:
            return ret
        for output in data.get('output', []):
          ret = self.lookup(type, index, output)
          if not ret is None:
            return ret

      return None

    @staticmethod
    def load(path, type, index):
      """
      Loads the object information from the given path and context.
      """
      ret = Occam.Object()
      ret._run_info = None
      ret._major_object = json.load(open('object.json'))
      if index is None:
        ret._object = ret._major_object
      else:
        ret._object = ret.lookup(type, index, ret._major_object['input'][0])
      ret._index = index;

      return ret

    def load_internal(self, type, index):
      ret = Occam.Object()
      ret._run_info = None
      ret._major_object = self._major_object
      ret._index = index
      ret._object = self.lookup(type, index, self._major_object['input'][0])
      return ret

    def output(self):
      return "%s/run-out.raw" % (self.path())

    def name(self):
      if "name" in self._object:
        return self._object["name"]
      else:
        return "unnamed"

    def slugType(self):
      return self.type().replace('/', '-').lower()

    def type(self):
      if "type" in self._object:
        return self._object["type"]
      else:
        return "object"

    def id(self):
      if "id" in self._object:
        return self._object["id"]
      else:
        return ""

    def revision(self):
      if "revision" in self._object:
        return self._object["revision"]
      else:
        return ""

    def index(self):
      return self._index

    def tag(self):
      return str(self.index())

    def volume(self):
      if self.index() is None:
        path = os.path.join(".", "occam-run", "%s-%s" % (self.slugType(), self.id()))
        return path
      else:
        return os.path.join("/", "occam", "%s-%s" % (self.id(), self.revision()))

    def path(self):
      if self.index() is None:
        path = os.path.join(".", "occam-run", self.tag())
        return path
      else:
        return os.path.join(".", "objects", self.tag())

    def initializationPath(self):
      if self.index() is None:
        path = os.path.join(".", "occam-run", self.tag())
        return path
      else:
        return os.path.join(".", "init", self.tag())

    def files(self):
      ret = []
      for path in self._object.get('files', []):
        ret.append(os.path.join(self.volume(), path))

      return ret

    def configuration(self, name):
      def set_default(schema, current):
        for k, v in schema.items():
          if "type" in v and not isinstance(v["type"], dict):
            # Item
            if "default" in v:
              if "type" in v:
                # Ensure the correct type, just in case
                if v["type"] == "int":
                  v["default"] = int(v["default"])
                elif v["type"] == "float":
                  v["default"] = float(v["default"])
              current[k] = v["default"]
            else:
              print("Warning: no default for key %s" % (k))
          else:
            # Group
            if not k in current:
              current[k] = {}
            set_default(v, current[k])

      ret = {}
      if self._index is None:
        # Native object, pull defaults
        for configuration in self._object["configurations"]:
          if "name" in configuration and configuration["name"] == name:
            if "schema" in configuration:
              schema = configuration["schema"]
            if isinstance(schema, (str, unicode)):
              configuration_path = os.path.join(".", schema)
              schema = json.load(open(configuration_path, 'r'))

            set_default(schema, ret)
      elif "configurations" in self._object:
        # Input object, pull configuration:
        if name in self._object["configurations"]:
          ret = self._object["configurations"][name]

          if isinstance(ret, (str, unicode)):
            configuration_path = os.path.join(".", "config", self.tag(), ret)
            ret = json.load(open(configuration_path, 'r'))

      return ret


    def configuration_file(self, name):
      configuration_path = ""
      if "configurations" in self._object:
        # Input object, pull configuration:
        if name in self._object["configurations"]:
          config_file = self._object["configurations"][name]
          if isinstance(config_file, (str, unicode)):
            configuration_path = os.path.join(".", "config", self.tag(), config_file)

      return configuration_path

    def output_path(self, type=None, output_directory='.', output_file="", output_name="output"):
      output_dir = os.path.realpath(self.path())
      output_dir = os.path.join(output_dir, output_directory)
      if not os.path.exists(output_dir):
        os.mkdir(output_dir)
      out_obj_file = os.path.join(output_dir, 'object.json')
      obj_found = os.path.exists(out_obj_file)
      with open(out_obj_file,'w+') as json_file:
        gen_object={}
        if(obj_found):
          gen_object=json.load(json_file)
        gen_object["files"] = [ output_file ]
        if(output_name!=None):
          gen_object["name"]=output_name
        json_file.write(json.dumps(gen_object, indent=4, separators=(',', ': ')))
      return os.path.join(output_dir,output_file)

    def output_generated_path(self, type=None, output_directory='.', output_file="", output_name="output"):
      output_dir = None
      if (type != None):
        connection_to_output = self.outputs(type)
        if len(connection_to_output) > 0:
          output_block = connection_to_output[0]
          output_dir = output_block.volume()
        else:
          return None
      if not os.path.exists(output_dir):
        os.mkdir(output_dir)
      out_obj_file = os.path.join(output_dir, 'object.json')
      obj_found = os.path.exists(out_obj_file)
      with open(out_obj_file,'w+') as json_file:
        gen_object={}
        if(obj_found):
          gen_object=json.load(json_file)
        gen_object["files"] = [ output_file ]
        if(output_name!=None):
          gen_object["name"]=output_name
        json_file.write(json.dumps(gen_object, indent=4, separators=(',', ': ')))
      return os.path.join(output_dir,output_file)

    def configurations(self):
      if "configurations" in self._object:
        return self._object["configurations"]
      else:
        return {}

    def dependencies(self):
      if "dependencies" in self._object:
        return self._object["dependencies"]
      else:
        return []

    def outputs(self, type=None):
      # Map these indices to objects
      ret = []
      for info in self._object.get('output', []):
        if type is None or info['type'] == type:
          ret.append(self.load_internal(info['type'], info['index']))
      return ret



    def inputs(self, type=None):
      # Map these indices to objects
      ret = []
      for info in self._object.get('input', []):
        if type is None or info['type'] == type:
          ret.append(self.load_internal(info['type'], info['index']))
      return ret

    def command(self):
      # Check for an run json
      if self._run_info is None:
        self._run_info = json.load(open("%s/run.json" % self.initializationPath()))

      if "command" in self._run_info:
        return self._run_info["command"]
      else:
        return None

    def env(self):
      # Check for an run json
      if self._run_info is None:
        self._run_info = json.load(open("%s/run.json" % self.path()))

      if "env" in self._run_info:
        return self._run_info["env"]
      else:
        return None

  @staticmethod
  def load():
    """
    Loads the object from the current directory based on the context
    given to us by the OCCAM system.
    """
    major_object = json.load(open('object.json'))

    if 'OCCAM_OBJECT_TYPE' in os.environ:
      type = os.environ['OCCAM_OBJECT_TYPE']
    elif "type" in major_object:
      type = major_object["type"]
    else:
      raise Exception("Cannot understand what type of object we are.")

    if 'OCCAM_OBJECT_INDEX' in os.environ:
      index = int(os.environ['OCCAM_OBJECT_INDEX'])
    else:
      index = None

    return Occam.Object.load("object.json", type, index)

  @staticmethod
  def finish(warnings=[], errors=[]):
    """
    Reports to the OCCAM system how to run this artifact.
    """
    object = Occam.load()

    run_json_filename = "%s/run.json" % (object.path())
    run_info = {}

    if os.path.exists(run_json_filename):
      f = open(run_json_filename, "r")
      run_info = json.load(f)
      f.close()

    run_info["warnings"] = warnings
    run_info["errors"]   = errors

    f = open(run_json_filename, "w+")
    f.write(json.dumps(run_info))
    f.close()

  @staticmethod
  def report(command, finish=None, env={}):
    """
    Reports to the OCCAM system how to run this artifact.
    """
    object = Occam.load()
    run_info = []
    if isinstance(command, list):
        for r_command in command:
            run_info.append({
              "variables": env,
              "command": r_command,
              "stdout": "output.raw"
            })
    else:
        run_info.append({
          "variables": env,
          "command": command,
          "stdout": "output.raw"
        })

    if not finish is None:
      run_info.append({
        "command": finish
      })

    run_json_filename = os.path.join(".", "init", object.tag(), "run.json")

    f = open(run_json_filename, "w+")
    f.write(json.dumps(run_info))
    f.close()
