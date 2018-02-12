## Getting Started

### Creating a Window

We need a window and an OpenGL context to draw in. This is OS specific, libraries exist to help e.g. GLUT, SDL, SFML and GLFW.
Using GLFW we can create an OpenGL context, as well as a window with parameters and also handle user input. It also provides callbacks for useful events, such as user input or window resizing.

Another OS specific issue is the location of the OpenGL functions provided by a particular graphics card drivers. GLAD is a library that helps to simplify this process.

Double buffering is a technique that makes changes to a secondary buffer object, then when complete updates the main buffer in one go, rather than updating the main buffer incrementally. Resulting in smoother frame transitions.

See [the code](Hello/main.cpp) for actual usage.

### Basic Triangle

The graphics pipeline takes a 3D object and outputs 2D pixels to the screen. The main interactions a programmer has with the pipeline is with the vertex and fragment shader programs. 

The vertex shader operates on a 3D vertex and outputs a 3D vertex that has been manipulated in some way by the program. The fragment shader takes a rasterized fragment and is used to determine the final colour of the output pixel.

OpenGL uses normalized device coordinates (NDC) to define vertices, where *x*, *y* and *z* range from *-1* to *+1*.

To send vertices to the vertex shader we need to store them in a *vertex buffer object* (VBO). Buffers are generated using:

```c
unsigned int VBO;
glGenBuffers(1, &VBO); // first arg is num of buffers to gen
```

A buffer needs to bound to an OpenGL buffer type to be usable, for a VBO the type is `GL_ARRAY_BUFFER` and its bound using:

```c
glBindBuffer(GL_ARRAY_BUFFER, VBO);
```

After the buffer is bound any buffer operations on the `GL_ARRAY_BUFFER` type will effect the *VBO* object we created and bound. The vertex data can be copied into the buffer with:

```c
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
```

The fourth arg of `glBufferData` indicates how changeable the data is likely to be, `GL_STATIC_DRAW` means it will chnage very rarely, other options are `GL_DYNAMIC_DRAW` and `GL_STREAM_DRAW` for different degrees of dynamic data.

Shaders are separate programs written in the OpenGL Shading Language (GLSL). The most basic of vertex shaders can be seen below.

```glsl
#version 330 core
layout (location = 0) in vec3 aPos;

void main()
{
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}
```

A shader program begins with a version declaration and optionally a profile, in the example GLSL 3.3 and the core profile. All input vertex attributes are defined with the *in* keyword. In this case the location of the attribute is also given with `layout (location = 0)`, this is used later to send the shader the vertex data to the correct place. The ouptut vertex is assigned to `gl_Position`.

In a similar way to buffer creation we must create a shader object, and assign the source (a string in this case) to the object, then finally compile the shader for use.

```c
unsigned int vertexShader;
vertexShader = glCreateShader(GL_VERTEX_SHADER);
glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
glCompileShader(vertexShader);
```

Fragment shaders are created in analogous manner, where the code would specify `out` vectors.

```glsl
#version 330 core
out vec4 FragColor;

void main()
{
    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
```

Next, the two shaders need to be attached to a shader program.

```c
unsigned int shaderProgram;
shaderProgram = glCreateProgram();
glAttachShader(shaderProgram, vertexShader);
glAttachShader(shaderProgram, fragmentShader);
glLinkProgram(shaderProgram);
glUseProgram(shaderProgram);
```

The shader compilation and linking procedures can be checked for errors, see [the code](Hello/main.cpp).

The next step is to define what data we will give to the vertex shader, vertex attributes allow us to send arbitrary data to the shader. We define it with `glVertexAttribPointer`, for example:

```c
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0); // references location set within the shader
```

A **vertex array object** (VAO) allows us to essentially save all this *vertex buffer* configuration, meaning it can be easily re-used. In fact, such an object is required by OpenGL Core. The definition is similar to a *VBO*.

```c
unsigned int VAO;
glGenVertexArrays(1, &VAO);
glBindVertexArray(VAO);
// bind the VBO (saved by VAO)
glBindBuffer(GL_ARRAY_BUFFER, VBO);
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0);  
// [render loop]
glUseProgram(shaderProgram);
glBindVertexArray(VAO);
```

To eventually draw the triangle we use `glDrawArrays(GL_TRIANGLES, 0, 3);`

A final type of buffer to mention is an **Element Buffer Object** (EBO). Used when we want to draw multiple objects from a set of vertices, say two triangles to make a rectangle. Instead of duplicating vertices the EBO is an array of indices into the vertex buffer. A *VAO* will also keep track of a bound *EBO*.

### Shaders

Shaders are programs that run directly on the GPU, and are written in GLSL which is a C-like language. The general structure of a shader is a version statement followed by input and output variables, then uniforms. The entry point is the `void main()` method.

For vertex shaders we call each input variable a *vertex attribute*, OpenGL provides a minimum of 16 but different hardware may provide more.

GLSL has types like other languages, e.g. `int, uint, float, bool`. It also has vector and matrix types. Vectors can have 1-4 elements denoted `vec, vec2, vec3, vec4` for *floats*, other vector types are `bvec, ivec, uvec, dvec` for *bool, int, uint* and *doubles*. Vector elements can be accessed with `xyzw`, `rgba` (colors) or `stpq` (textures). Swizzling allows the element access to be mixed up or repeated e.g. `.xxyy, .wxyz, .yyyy`. Vector constructors can take a vector variable to be fully or partially substituted for its params e.g. `vec4(some_vec2, 0.0, 1.0)`.

Shaders are not able to communicate with each other directly, but only through their input and output. Using the `in` and `out` keywords we can define these variables. If the name of an output matches the input of the next shader, then OpenGL will link them together. 

Vertex shaders must have input which it receives directly from the vertex data. We configure the vertex data in the CPU side of our program and use *location metadata* on our input variable so the shader can find it, `layout (location = 0) in vec3 pos;`. The `layout` qualifier can be left out and instead use `glGetAttribLocation` in the OpenGL (CPU) code. Fragment shaders, on the other hand, must have a `vec4` output for color.

#### Uniforms

Uniforms are a another way to pass data from the CPU side to the GPU shader programs. Uniforms are global meaning they are defined on the shader program object and can be accessed by any shader linked to the program. They will also hold the value they have been assigned, until they are updated or reset. If you declare a uniform in your GLSL, but don't use it there, the compiler will remove it - causing annoying errors.

In GLSL we simply use the `uniform` keyword to define a uniform `uniform vec4 aVar;`. To assign some data to the uniform in GLSL we need to find the location of it in the shader, `glGetUniformLocation(shaderProgram, "aVar")` it returns *-1* if the location is not found. The value is then assigned with `glUniform4f(location, aVector4)`. As with other GLSL functions use the appropriate `glUniformXX()` method for the uniform type. It is not necessary to have called `glUseProgram` before getting the location, but it must be called before updating a uniform as the update will be on the active shader program.

#### Vertex Attributes Plus

As mentioned previously vertex data can hold more than just vertex coordinates, in fact any arbitrary data we require can be added. For example a color could be defined for each vertex, we simply add another three floats (r, g, b) after each vertex triple. The vertex attribute pointers need to be updated so the new data can retrieved correctly. The original position attribute stays much the same, but the *stride* value needs to be increased to skip the color values.

```c
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0);
```

The color attribute looks similar, with a different location (first arg) and offset (last arg).

```c
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3* sizeof(float)));
glEnableVertexAttribArray(1);
```

In the shader we define a new input along the lines of the position variable.

```c
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
```

Fragment shaders interpolate all its inputs across the fragments that it generates.
If we send this new vertex color to the fragment shader and use it as output we see a spectrum of colors on our triangle. From the defined vertex colors on the tree vertices of the triangle, the shader produces a linear interpolation based on the generated fragments location in relation to the specified vertices. For example 10% blue, 90% green, 0% red.

See the [code](Shaders/shader.h) for a method to load shaders from text files, rather than inserting strings into the C program.
