# escape=`

# Build stage: Uses the .NET Framework SDK image to build the application
FROM mcr.microsoft.com/dotnet/framework/sdk:4.8 AS build
WORKDIR /app

# Copy solution and project files
COPY *.sln .
COPY aspnetmvcapp/*.csproj ./aspnetmvcapp/
COPY aspnetmvcapp/*.config ./aspnetmvcapp/

# Restore NuGet packages (cached layer)
RUN nuget restore

# Copy application source code
COPY aspnetmvcapp/ ./aspnetmvcapp/
WORKDIR /app/aspnetmvcapp

# Build the application in Release configuration
RUN msbuild /p:Configuration=Release -r:False

# Runtime stage: Uses the smaller ASP.NET runtime image
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8 AS runtime
WORKDIR /inetpub/wwwroot

# Copy build artifacts from the build stage
COPY --from=build /app/aspnetmvcapp/. ./

# >>> ADD CONTRAST AGENT FILES <<<
RUN mkdir C:\Contrast
COPY --from=contrast/agent-dotnet-framework:latest C:\Contrast C:\Contrast

# >>> SET CONTRAST PROFILER ENV VARS <<<
# Enable the .NET Profiling API
ENV COR_ENABLE_PROFILING=1
# Set the GUID for the Contrast Profiler
ENV COR_PROFILER={EFEB8EE0-6D39-4347-A5FE-4D0C88BC5BC1}
# Set paths for 32-bit and 64-bit Contrast Profiler DLLs
ENV COR_PROFILER_PATH_32=C:\Contrast\runtimes\win-x86\native\ContrastProfiler.dll
ENV COR_PROFILER_PATH_64=C:\Contrast\runtimes\win-x64\native\ContrastProfiler.dll

# >>> SET CONTRAST AGENT ENV VARS <<<
# Agent configuration
ENV CONTRAST__AGENT__LOGGER__LEVEL=INFO
ENV CONTRAST__AGENT__LOGGER__STDOUT=true
ENV CONTRAST__ASSESS__ENABLE=true
ENV CONTRAST__PROTECT__ENABLE=true

# Note: Contrast API credentials (CONTRAST__API_*) are NOT set here.
# They will be injected securely via AWS Secrets Manager and ECS Task Definition.
