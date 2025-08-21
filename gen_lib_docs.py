import os
from editor.moduleviewer import find_defs

def process_def(definition):

    d = definition.strip()
    for s in ["let ", ";"]:
        d = d.replace(s, "")
    d, *comments = d.split("#")
    return "```haskell\n"+d.strip()+"\n```" + "\n\n" + "<br>\n".join(map(lambda c:"> "+c.strip(), comments)) + "\n\n"

def find_module_doc(path):
    acc = ""
    with open(path, "r") as f:
        for line in f:
            if line.startswith("##") and not line.startswith("###"):
                acc += line[3:].strip() + "\n"
    return acc

for f in os.listdir('examples/lib'):
    if not f.endswith(".ml"):
        continue
    with open("docs/LibDocs/"+f.removesuffix(".ml")+".md", "w") as doc:
        doc.write("---\n")
        doc.write("nav_order: 2\n")
        doc.write("title: " + f.removesuffix(".ml") + "\n")
        doc.write("parent: Library Documentation\n")
        doc.write("---\n\n")
        doc.write("# " + f + "\n\n")
        doc.write(find_module_doc("examples/lib/"+f) + "\n\n")
        doc.write("## Definitions\n\n")
        for _, line, d in find_defs("examples/lib/"+f, get_markdown_comments=True):
            if d.startswith("###"):
                doc.write(d.strip("#").strip()+ "\n")
            else:
                doc.write(process_def(d) + "\n")

with open("docs/LibDocs.md", "w") as doc:
    doc.write("---\n")
    doc.write("nav_order: 2\n")
    doc.write("---\n\n")
    doc.write("# Library Documentation\n\n")
    doc.write("This is the documentation for the libraries available in PocketML.\n\n")
    doc.write("## Libraries\n\n")
    for f in os.listdir('examples/lib'):
        if not f.endswith(".ml"):
            continue
        doc.write("- [" + f.removesuffix(".ml") + "](LibDocs/" + f.removesuffix(".ml") + ".md)\n")
        doc.write("\t>" + find_module_doc("examples/lib/"+f) + "\n\n")
