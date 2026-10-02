import xml.etree.ElementTree as ET

tree = ET.parse(r'p:\RakshaNet\architecture.drawio')
root = tree.getroot()
print(f'Root tag: {root.tag}, version: {root.attrib.get("version")}')
diagrams = root.findall('diagram')
print(f'Total diagrams: {len(diagrams)}')
total_cells = 0
for idx, d in enumerate(diagrams):
    name = d.attrib.get('name')
    did = d.attrib.get('id')
    model = d.find('mxGraphModel')
    cells = model.find('root').findall('mxCell') if model is not None else []
    total_cells += len(cells)
    print(f'  Diagram {idx+1}: [{did}] "{name}" - {len(cells)} cells')
print(f'Total cells across all diagrams: {total_cells}')
