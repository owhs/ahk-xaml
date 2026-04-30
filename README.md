# AHK-XAML

A framework for creating and manipulating rich, native Windows WPF/XAML Graphical User Interfaces directly from AutoHotkey v2. 

Because XAML functionality evolved significantly, the repository is split logically into three versions to serve different needs. Each directory contains its own `README.md` detailing its usage and architecture.

## Versions Overview

### [v1-powershell (Legacy)](v1-powershell/README.md)
The original version. It acts as a bridge between AHK and a background PowerShell engine that runs the WPF window. 
- *Pros:* No compilation required. 
- *Cons:* Slower startup time, legacy status (does not have feature parity with the newer versions).

### [v2-csc (Raw XAML)](v2-csc/README.md)
The upgraded core engine. Instead of PowerShell, it leverages the built-in Windows C# compiler (`csc.exe`) to dynamically compile a background executable (`.exe`).
- *Pros:* Instant boot times on subsequent runs (due to executable caching). Reliable and performant. 
- *Cons:* You still have to write raw `.xaml` layout files manually.

### [v3-generator (Latest)](v3-generator/README.md)
The most advanced version. It utilizes the powerful `v2-csc` C# background engine but introduces the **XAML_Generator** class.
- *Pros:* Allows you to build entire UIs procedurally within AHK using concise objects and methods. No need for separate raw `.xaml` files. The `XAML_Generator` class is fully decoupled and can be updated independently.
- *Cons:* Requires learning the `XAML_Generator` syntax.
